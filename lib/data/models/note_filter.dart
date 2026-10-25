/// Sorting options for notes.
enum NoteSortOption {
  dateModifiedNewest('Last Modified (Newest)'),
  dateModifiedOldest('Last Modified (Oldest)'),
  dateCreatedNewest('Created Date (Newest)'),
  dateCreatedOldest('Created Date (Oldest)'),
  titleAZ('Title (A to Z)'),
  titleZA('Title (Z to A)');

  final String label;
  const NoteSortOption(this.label);
}

/// Active view modes.
enum NotesViewMode { grid, list }

/// Main filter criteria.
class NoteFilter {
  final String category;
  final String searchQuery;
  final String? selectedTag;
  final bool onlyPinned;
  final bool onlyFavorite;
  final bool onlyArchived;
  final bool onlyTrash;
  final NoteSortOption sortOption;

  const NoteFilter({
    this.category = 'All',
    this.searchQuery = '',
    this.selectedTag,
    this.onlyPinned = false,
    this.onlyFavorite = false,
    this.onlyArchived = false,
    this.onlyTrash = false,
    this.sortOption = NoteSortOption.dateModifiedNewest,
  });

  NoteFilter copyWith({
    String? category,
    String? searchQuery,
    String? selectedTag,
    bool? onlyPinned,
    bool? onlyFavorite,
    bool? onlyArchived,
    bool? onlyTrash,
    NoteSortOption? sortOption,
  }) {
    return NoteFilter(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: selectedTag ?? this.selectedTag,
      onlyPinned: onlyPinned ?? this.onlyPinned,
      onlyFavorite: onlyFavorite ?? this.onlyFavorite,
      onlyArchived: onlyArchived ?? this.onlyArchived,
      onlyTrash: onlyTrash ?? this.onlyTrash,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}
