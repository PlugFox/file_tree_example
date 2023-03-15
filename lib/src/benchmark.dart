import 'package:args/command_runner.dart';

class BenchmarkCommand extends Command<void> {
  BenchmarkCommand();

  @override
  final name = 'benchmark';

  @override
  final description = 'Benchmark the file tree model.';

  // [run] may also return a Future.
  @override
  void run() {
    print('Benchmark');
  }
}
