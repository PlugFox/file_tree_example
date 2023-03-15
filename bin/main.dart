import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file_tree_example/src/benchmark.dart';
import 'package:file_tree_example/src/generate.dart';
import 'package:file_tree_example/src/memory.dart';

// dart compile exe bin\main.dart -o main.exe
void main(List<String> args) => (App()
      ..addCommand(GenerateCommand())
      ..addCommand(BenchmarkCommand())
      ..addCommand(MemoryCommand()))
    .run(args);

class App extends CommandRunner<void> {
  App()
      : super(
          <String>['script', ...io.Platform.script.pathSegments].last,
          'Just a simple example and benchmark for the file tree model.',
        );
}
