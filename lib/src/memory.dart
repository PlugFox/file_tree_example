import 'package:args/command_runner.dart';

class MemoryCommand extends Command<void> {
  MemoryCommand();

  @override
  final name = 'memory';

  @override
  final description = 'Benchmark the memory usage of the file tree model.';

  // [run] may also return a Future.
  @override
  void run() {
    print('Memory');
  }
}
