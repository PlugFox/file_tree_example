// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:args/command_runner.dart';
import 'package:file_tree_example/src/node.dart';

class GenerateCommand extends Command<void> {
  GenerateCommand() {
    argParser
      ..addOption(
        'count',
        abbr: 'c',
        help: 'The number of nodes to generate.',
        callback: (value) {
          if (value == null) return;
          _totalCount = int.tryParse(value) ?? _totalCount;
        },
        defaultsTo: _totalCount.toString(),
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'The output file path to save the generated tree to as JSON.',
        callback: (value) {
          if (value == null || value.isEmpty) return;
          _path = value;
        },
        defaultsTo: _path,
      );
  }

  @override
  final name = 'generate';

  @override
  final description = 'Generate random tree and save it to a JSON file.';

  /// The number of nodes to generate.
  int _totalCount = 1000000;

  String _path = 'tree.json';

  // [run] may also return a Future.
  @override
  void run() {
    print('Start generating $_totalCount nodes...');
    var generated = 0;
    final stopwatch = Stopwatch()..start();
    final math.Random rnd = math.Random();
    final generateFor = <Node$Directory>[];
    void generateChildren(Node$Directory node) {
      try {
        if (stopwatch.elapsed.inSeconds > 10) {
          print('Generated $generated nodes in ${stopwatch.elapsed}.');
          stopwatch.reset();
        }
        final count = rnd.nextInt(5);
        final children = <Node>[];
        for (var i = 0;
            i < count && generated < _totalCount;
            i++, generated++) {
          Node child;
          switch (rnd.nextInt(3)) {
            case 0:
              child = Node.directory(
                id: -generated,
                name: 'dir#${generated.toRadixString(36)}',
                parent: node,
              );
              break;
            default:
              child = Node.file(
                id: generated,
                name: 'file#${generated.toRadixString(36)}',
                parent: node,
              );
              break;
          }
          children.add(child);
        }
        $NodeChanger.addChildren(node, children);
        node.visitChildNodes((node) {
          if (node is Node$Directory) generateFor.add(node);
        });
      } on Object catch (error, stackTrace) {
        print('$error\n$stackTrace');
      }
    }

    final root = Node$Directory(id: 0, name: 'root', children: <Node>[]);
    generated++;
    while (generated < _totalCount) {
      if (generateFor.isEmpty) generateFor.add(root);
      while (generateFor.isNotEmpty) generateChildren(generateFor.removeLast());
    }
    stopwatch.stop();
    print('Done generating $_totalCount nodes.');
    try {
      print('Start converting Node tree to JSON...');
      final encodedJson = root.toJson();
      print('Start converting JSON to String ...');
      final jsonRaw = JsonEncoder.withIndent(' ').convert(encodedJson);
      print('Try to decode String back to JSON...');
      final decodedJson = jsonDecode(jsonRaw);
      print('Try to decode JSON back to tree...');
      final decoded = Node.fromJson(decodedJson);
      print('Check count...');
      var count = 1;
      decoded.visitDescendantNodes((node) {
        count++;
        //if (node.parent == null) throw Exception('Parent is null.');
        return true;
      });
      if (count != _totalCount)
        throw Exception('Count mismatch: $count != $_totalCount.');

      print('Start saving to JSON...');
      io.File(_path).writeAsStringSync(jsonRaw);
    } on Object catch (error, stackTrace) {
      print('$error\n$stackTrace');
      io.exit(2);
    }
    print('Done saving to JSON.');
    io.exit(0);
  }
}
