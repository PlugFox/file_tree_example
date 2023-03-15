import 'dart:collection';

import 'package:meta/meta.dart';

typedef NodeId = String;
typedef NodeVisitor = void Function(Node node);

/// A node in the file system
abstract class Node {
  Node({
    required this.id,
    required this.name,
  });

  /// Creates a file node
  factory Node.file({
    required NodeId id,
    required String name,
  }) = Node$File;

  /// Creates a directory node
  factory Node.directory({
    required NodeId id,
    required String name,
    required List<Node> children,
  }) = Node$Directory;

  /// The unique identifier of the node
  @nonVirtual
  final NodeId id;

  /// The name of the node
  @nonVirtual
  final String name;

  /// Whether the node is a file
  @nonVirtual
  bool get isFile => !isDirectory;

  /// Whether the node is a directory
  abstract final bool isDirectory;

  /// Whether the node has a parent
  bool get isRoot => _$parent != null;

  /// The parent of the node
  Node$Directory? get parent => _$parent;
  Node$Directory? _$parent;

  /// Visit the childrens of the node
  void visitChildNodes(NodeVisitor visitor);

  /// Walks the descendant chain and visit all the nodes of the tree
  /// The walk stops when it reaches the root widget
  /// or when the callback returns false.
  void visitDescendantNodes(bool Function(Node node) visitor) {
    final q = Queue<Node>()..add(this);
    Node n;
    while (q.isNotEmpty) {
      n = q.removeFirst();
      if (!visitor(n)) return;
      n.visitChildNodes(q.add);
    }
  }

  /// Converts the node to a JSON object
  Map<String, Object?> toJson();

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Node && id == other.id;

  @override
  String toString() => id;
}

/// A file node
class Node$File extends Node {
  Node$File({
    required super.id,
    required super.name,
  });

  @override
  bool get isDirectory => false;

  @override
  void visitChildNodes(NodeVisitor visitor) {}

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'type': 'file',
      };
}

/// A directory node
class Node$Directory extends Node {
  Node$Directory({
    required super.id,
    required super.name,
    required Iterable<Node> children,
  }) : _children = List<Node>.of(children);

  List<Node> get children => UnmodifiableListView<Node>(_children);
  final List<Node> _children;

  @override
  bool get isDirectory => true;

  @override
  void visitChildNodes(NodeVisitor visitor) {
    for (final child in _children) {
      visitor(child);
    }
  }

  @override
  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'type': 'dir',
        'children':
            _children.map<Map<String, Object?>>((e) => e.toJson()).toList(),
      };
}
