// Root entry point delegating to the production-quality modular architecture in lib/
import 'lib/main.dart' as app;

export 'lib/main.dart';

Future<void> main() async {
  await app.main();
}
