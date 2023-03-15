import 'package:args/command_runner.dart';

class GenerateCommand extends Command<void> {
  GenerateCommand() {
    argParser.addOption(
      'count',
      abbr: 'c',
      help: 'The number of nodes to generate.',
      callback: (value) {
        if (value == null) return;
        _count = int.tryParse(value) ?? _count;
      },
      defaultsTo: '1000000',
    );
  }

  @override
  final name = 'generate';

  @override
  final description = 'Generate random tree and save it to a JSON file.';

  /// The number of nodes to generate.
  int _count = 1000000;

  // [run] may also return a Future.
  @override
  void run() {
    print('generate $_count nodes');
  }
}
