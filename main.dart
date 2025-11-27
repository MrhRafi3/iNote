// main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotesDB.instance.init(); // load DB before UI
  runApp(const NotepadApp());
}

// ---------------- App ----------------
class NotepadApp extends StatefulWidget {
  const NotepadApp({super.key});
  @override
  State<NotepadApp> createState() => _NotepadAppState();
}

class _NotepadAppState extends State<NotepadApp> {
  bool darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => darkMode = prefs.getBool('darkMode') ?? true);
  }

  Future<void> _saveTheme(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', v);
    setState(() => darkMode = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: darkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: darkMode ? Colors.black : Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent, brightness: darkMode ? Brightness.dark : Brightness.light),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iNotepad',
      theme: theme,
      home: HomeShell(darkMode: darkMode, onThemeChange: _saveTheme),
    );
  }
}

// ---------------- NotesDB (robust) ----------------
class NotesDB {
  NotesDB._();
  static final NotesDB instance = NotesDB._();

  static const _kNotes = 'notes_v2';
  static const _kIdCounter = 'notes_id_counter';

  List<Map<String, dynamic>> notes = [];
  int _idCounter = 0;

  /// Call once at app start (before runApp) to avoid races.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // load id counter (if exists)
    _idCounter = prefs.getInt(_kIdCounter) ?? 0;

    final raw = prefs.getString(_kNotes);
    if (raw == null) {
      notes = [];
      return;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      notes = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // ensure notes have required fields and fix missing ids
      for (var n in notes) {
        if (n['id'] == null) {
          n['id'] = ++_idCounter;
        }
        n['pinned'] = n['pinned'] ?? false;
        n['category'] = n['category'] ?? 'Normal';
        n['createdAt'] = n['createdAt'] ?? DateTime.now().toIso8601String();
      }

      // ensure _idCounter >= max existing id
      final ids = notes.where((n) => n['id'] is int).map((n) => n['id'] as int);
      if (ids.isNotEmpty) {
        final maxId = ids.reduce((a, b) => a > b ? a : b);
        if (maxId > _idCounter) _idCounter = maxId;
      }

      // persist corrected id counter (if changed)
      await prefs.setInt(_kIdCounter, _idCounter);
      await prefs.setString(_kNotes, jsonEncode(notes));
    } catch (e) {
      // if corrupted JSON, reset
      notes = [];
      _idCounter = prefs.getInt(_kIdCounter) ?? 0;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNotes, jsonEncode(notes));
    await prefs.setInt(_kIdCounter, _idCounter);
  }

  Future<int> _nextId() async {
    _idCounter++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIdCounter, _idCounter);
    return _idCounter;
  }

  Future<void> addNote(Map<String, dynamic> note) async {
    final id = await _nextId();
    final newNote = <String, dynamic>{
      'id': id,
      'text': note['text'] ?? '',
      'category': note['category'] ?? 'Normal',
      'pinned': note['pinned'] ?? false,
      'createdAt': note['createdAt'] ?? DateTime.now().toIso8601String(),
    };
    notes.add(newNote);
    await _persist();
  }

  Future<void> updateNote(int id, Map<String, dynamic> payload) async {
    final idx = notes.indexWhere((n) => n['id'] == id);
    if (idx >= 0) {
      notes[idx] = {...notes[idx], ...payload};
      await _persist();
    }
  }

  Future<void> removeNote(int id) async {
    notes.removeWhere((n) => n['id'] == id);
    await _persist();
  }
}

// ---------------- Home Shell ----------------
class HomeShell extends StatefulWidget {
  final bool darkMode;
  final Function(bool) onThemeChange;
  const HomeShell({super.key, required this.darkMode, required this.onThemeChange});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      NotesPage(darkMode: widget.darkMode),
      PinnedPage(darkMode: widget.darkMode),
      SettingsPage(darkMode: widget.darkMode, onThemeChange: widget.onThemeChange),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: widget.darkMode ? Colors.black : Colors.white,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: widget.darkMode ? Colors.white70 : Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.push_pin), label: 'Pinned'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          final payload = await Navigator.push<Map<String, dynamic>>(
              context, MaterialPageRoute(builder: (_) => const EditNotePage()));
          if (payload != null) {
            await NotesDB.instance.addNote(payload);
            // refresh top page by rebuilding (NotesPage reads from DB in init)
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------- Notes Page ----------------
class NotesPage extends StatefulWidget {
  final bool darkMode;
  const NotesPage({super.key, this.darkMode = true});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> filtered = [];
  final TextEditingController searchController = TextEditingController();
  String category = 'All';
  bool loading = true;
  bool gridView = true;

  @override
  void initState() {
    super.initState();
    _load();
    searchController.addListener(_onSearch);
  }

  Future<void> _load() async {
    setState(() => loading = true);
    await NotesDB.instance.init(); // safe to call multiple times
    notes = List<Map<String, dynamic>>.from(NotesDB.instance.notes);
    _applyFilters();
    setState(() => loading = false);
  }

  void _onSearch() => _applyFilters();

  void _applyFilters() {
    final q = searchController.text.trim().toLowerCase();
    filtered = notes.where((n) {
      final text = (n['text'] ?? '').toString().toLowerCase();
      final cat = (n['category'] ?? 'Normal').toString();
      final matchesQ = q.isEmpty ? true : text.contains(q);
      final matchesC = category == 'All' ? true : cat == category;
      return matchesQ && matchesC;
    }).toList();

    filtered.sort((a, b) {
      final pa = (a['pinned'] ?? false) as bool;
      final pb = (b['pinned'] ?? false) as bool;
      if (pa && !pb) return -1;
      if (!pa && pb) return 1;
      final da = DateTime.parse(a['createdAt'] as String);
      final db = DateTime.parse(b['createdAt'] as String);
      return db.compareTo(da);
    });

    setState(() {});
  }

  Future<void> _refreshAll() async {
    await NotesDB.instance.init();
    notes = List<Map<String, dynamic>>.from(NotesDB.instance.notes);
    _applyFilters();
  }

  Widget _noteCard(Map<String, dynamic> n) {
    final dark = widget.darkMode;
    final cardColor = dark ? Colors.grey[900] : Colors.white;
    final textColor = dark ? Colors.white : Colors.black;
    final shadowColor = dark ? Colors.white12 : Colors.black12;

    final pinnedNow = (n['pinned'] ?? false) as bool;

    return Dismissible(
      key: ValueKey(n['id']),
      direction: DismissDirection.horizontal,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // swipe right -> toggle pin
          await NotesDB.instance.updateNote(n['id'] as int, {'pinned': !pinnedNow});
          await _refreshAll();
          return false; // don't dismiss
        } else {
          // swipe left -> delete confirmation
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Delete note?'),
              content: const Text('This will permanently delete the note.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
              ],
            ),
          );
          if (ok == true) {
            await NotesDB.instance.removeNote(n['id'] as int);
            await _refreshAll();
            return true;
          }
          return false;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.push_pin, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () async {
          final res = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => EditNotePage(existing: n)),
          );
          if (res != null) {
            await NotesDB.instance.updateNote(n['id'] as int, res);
            await _refreshAll();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(6, 6), blurRadius: 12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top row with pin toggle (tapable) to reliably pin/unpin
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      pinnedNow ? Icons.push_pin : Icons.push_pin_outlined,
                      color: pinnedNow ? Colors.redAccent : Colors.white70,
                      size: 18,
                    ),
                    onPressed: () async {
                      await NotesDB.instance.updateNote(n['id'] as int, {'pinned': !pinnedNow});
                      await _refreshAll();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(child: SingleChildScrollView(child: Text(n['text'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red[50],
                      ),
                      child: Text(
                        n['category'] ?? 'Normal',
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(n['createdAt'] as String),
                    style: TextStyle(fontSize: 11, color: dark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cats = <String>{'All'}..addAll(notes.map((e) => e['category'] ?? 'Normal'));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.darkMode ? Colors.black : Colors.white,
        title: const Text('iNOTE'),
        actions: [
          IconButton(icon: Icon(gridView ? Icons.view_list : Icons.grid_view), onPressed: () => setState(() => gridView = !gridView)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), child: const Text('By Mrh Rafi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: (_) => _applyFilters(),
                style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: widget.darkMode ? Colors.white54 : Colors.black45),
                  prefixIcon: Icon(Icons.search, color: widget.darkMode ? Colors.white70 : Colors.black45),
                  filled: true,
                  fillColor: widget.darkMode ? Colors.grey[850] : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: cats.map((c) {
                  final sel = c == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: sel,
                      selectedColor: Colors.redAccent,
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.red),
                      onSelected: (_) {
                        // set category and immediately apply filters
                        setState(() => category = c);
                        _applyFilters();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                  : filtered.isEmpty
                  ? Center(child: Text('No Notes Yet', style: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54)))
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: gridView ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _noteCard(filtered[i]),
                ) : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => SizedBox(height: 120, child: _noteCard(filtered[i])),
                ),
              ),
            ),
            const SizedBox(height: 10),
            //Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)), child: const Text('@ Mrh Rafi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}

// ---------------- Edit Note Page ----------------
class EditNotePage extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const EditNotePage({super.key, this.existing});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final TextEditingController controller = TextEditingController();
  String category = 'Normal';
  final List<String> categories = ['Normal', 'Personal', 'Ideas', 'work'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      controller.text = widget.existing!['text'] ?? '';
      category = widget.existing!['category'] ?? 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Note' : 'Create Note')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: controller,
            maxLines: 12,
            minLines: 6,
            decoration: InputDecoration(hintText: 'Write your note...', filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 12),
          Row(children: [
            DropdownButton<String>(value: category, items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => category = v ?? 'Normal')),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                final payload = {'text': controller.text.trim(), 'category': category};
                Navigator.pop(context, payload);
              },
              child: Text(isEdit ? 'Save Changes' : 'Save'),
            ),
          ])
        ]),
      ),
    );
  }
}

// ---------------- Pinned Page ----------------
class PinnedPage extends StatefulWidget {
  final bool darkMode;
  const PinnedPage({super.key, this.darkMode = true});

  @override
  State<PinnedPage> createState() => _PinnedPageState();
}

class _PinnedPageState extends State<PinnedPage> {
  List<Map<String, dynamic>> pinned = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPinned();
  }

  Future<void> _loadPinned() async {
    setState(() => loading = true);
    await NotesDB.instance.init();
    pinned = NotesDB.instance.notes.where((n) => n['pinned'] == true).toList();
    // sort same as main page (pinned first & newest)
    pinned.sort((a, b) {
      final da = DateTime.parse(a['createdAt'] as String);
      final db = DateTime.parse(b['createdAt'] as String);
      return db.compareTo(da);
    });
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned')),
      body: RefreshIndicator(
        onRefresh: _loadPinned,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
            : pinned.isEmpty
            ? Center(child: Text('No pinned notes', style: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54)))
            : GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: pinned.length,
          itemBuilder: (_, i) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: widget.darkMode ? Colors.grey[900] : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: widget.darkMode ? Colors.white12 : Colors.black12, offset: const Offset(4,4), blurRadius: 12)]),
            child: Text(pinned[i]['text'] ?? '', style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black)),
          ),
        ),
      ),
    );
  }
}

// ---------------- Settings Page ----------------
class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final Function(bool) onThemeChange;
  const SettingsPage({super.key, required this.darkMode, required this.onThemeChange});

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        SwitchListTile(value: darkMode, onChanged: onThemeChange, title: const Text('Dark Mode')),
        const Divider(),
        ListTile(leading: const Icon(Icons.contact_mail), title: const Text('Contact'), subtitle: const Text('Email: mrhrafi@hotmail.com\ngithub.com/mrhrafi3 '), onTap: () => _launchEmail('rafi@example.com')),
        const Divider(),
        ListTile(leading: const Icon(Icons.info), title: const Text('About'), subtitle: const Text('Version 1.0')),
        const Divider(),
        ListTile(leading: const Icon(Icons.feedback), title: const Text('Feedback'), onTap: () => _launchEmail('mrhrafi99@gmail.com')),
      ]),
    );
  }
}