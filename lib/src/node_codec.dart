part of 'node.dart';

class NodeCodec extends Codec<Node, Object> {
  const NodeCodec();

  @override
  final Converter<Node, Object> encoder = const NodeToJsonEncoder();

  @override
  final Converter<Object, Node> decoder = const NodeFromJsonDecoder();
}

class NodeToJsonEncoder extends Converter<Node, Object> {
  const NodeToJsonEncoder();

  @override
  Object convert(Node input) {
    Map<String, Object?> fileToJson(Node$File node) => <String, Object?>{
          'id': node._$id,
          'parent': node._$parent?.target?._$id,
          'type': 'file',
          'name': node._$name,
        };
    Map<String, Object?> dirToJson(Node$Directory node) => <String, Object?>{
          'id': node._$id,
          'parent': node._$parent?.target?._$id,
          'type': 'dir',
          'name': node._$name,
        };
    return input.map<Object>(
      file: fileToJson,
      directory: (node) {
        final list = <Map<String, Object?>>[
          dirToJson(node),
        ];
        node.visitDescendantNodes((node) {
          list.add(
            node.map<Map<String, Object?>>(
              file: fileToJson,
              directory: dirToJson,
            ),
          );
          return true;
        });
        return list;
      },
    );
  }
}

class NodeFromJsonDecoder extends Converter<Object, Node> {
  const NodeFromJsonDecoder();

  @override
  Node convert(Object input) {
    Node fileFromJson(Map<String, Object?> json) => Node.file(
          id: json['id'] as int,
          name: json['name'] as String,
        );
    Node dirFromJson(Map<String, Object?> json) => Node.directory(
          id: json['id'] as int,
          name: json['name'] as String,
        );
    if (input is Map<String, Object?>) {
      return input['type'] == 'file' ? fileFromJson(input) : dirFromJson(input);
    } else if (input is! List<Object?>) {
      throw ArgumentError.value(input, 'input', 'Expected a list or map');
    }
    final registry = <NodeId, Node>{}; // Node Id : Node
    for (final item in input) {
      if (item is! Map<String, Object?>) {
        throw StateError('Unexpected node type');
      }
      final node =
          item['type'] == 'file' ? fileFromJson(item) : dirFromJson(item);
      registry[node._$id] = node;
    }
    Node$Directory? root; // Root node
    for (final item in input) {
      if (item is! Map<String, Object?>) {
        throw StateError('Unexpected node type');
      }
      final node = registry[item['id'] as int]!;
      final parent = registry[item['parent']] as Node$Directory?;
      if (root == null && parent == null && node is Node$Directory) {
        root = node;
      } else if (parent is Node$Directory) {
        node._$parent = WeakReference<Node$Directory>(parent);
        parent._$children.add(node);
      } else {
        throw StateError('Unexpected behavior');
      }
    }
    registry[0];
    return root ?? (throw StateError('Root node not found'));
  }
}
