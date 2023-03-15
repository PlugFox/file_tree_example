import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart';
// https://pub.dev/packages/vm_service
import 'package:vm_service/vm_service.dart' show MemoryUsage, VM, VmService;
import 'package:vm_service/vm_service_io.dart' show vmServiceConnectUri;

import 'node.dart';

class MemoryCommand extends Command<void> {
  MemoryCommand() {
    argParser.addOption(
      'input',
      abbr: 'i',
      help: 'The input file path to decode the generated tree from JSON.',
      callback: (value) {
        if (value == null || value.isEmpty) return;
        _path = value;
      },
      defaultsTo: _path,
    );
  }

  @override
  final name = 'memory';

  @override
  final description = 'Benchmark the memory usage of the file tree model.';

  String _path = 'tree.json';

  // [run] may also return a Future.
  @override
  Future<void> run() async {
    bool debug = false;
    assert(debug = true);
    if (!debug) {
      print('Run in debug mode to benchmark the memory usage.');
      return;
    }
    print('Memory before creating the tree:');
    MemoryUsage memBefore = await _getMemoryUsage();
    final formatter = NumberFormat.compact();
    String format(int? bytes) =>
        '${formatter.format((bytes ?? 0) / (1024 * 1024))} MB';
    print('External usage: ${format(memBefore.externalUsage)}');
    print('Heap: ${format(memBefore.heapUsage)} / '
        '${format(memBefore.heapCapacity)}');
    final file = io.File('tree.json');
    if (!file.existsSync()) {
      throw Exception('File not found: ${file.path}');
    }
    final node = _decode(file);
    await Future<void>.delayed(const Duration(seconds: 5));
    MemoryUsage memAfter = await _getMemoryUsage();
    print('');
    print('Memory after creating the tree:');
    print('External usage: ${format(memAfter.externalUsage)}');
    print('Heap: ${format(memAfter.heapUsage)} / '
        '${format(memAfter.heapCapacity)}');
    assert(node.isRoot, 'The root node must be a directory node.');
  }

  static Node _decode(io.File file) =>
      Node.fromJson(jsonDecode(file.readAsStringSync()));

  Future<MemoryUsage> _getMemoryUsage() async {
    developer.ServiceProtocolInfo info = await developer.Service.getInfo();
    VmService service =
        await vmServiceConnectUri(info.serverWebSocketUri.toString());
    try {
      VM vm = await service.getVM();
      String? isolateId = vm.isolates?.first.id;
      MemoryUsage mem;
      if (isolateId == null) {
        mem = MemoryUsage(externalUsage: 0, heapCapacity: 0, heapUsage: 0);
      } else {
        mem = await service.getMemoryUsage(isolateId);
      }
      return mem;
    } finally {
      service.dispose();
    }
  }
}
