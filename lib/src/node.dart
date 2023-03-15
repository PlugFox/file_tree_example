import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart';

part 'node_codec.dart';

typedef NodeId = int;
typedef NodeVisitor = void Function(Node node);

/// A node in the file system
abstract class Node {
  Node({
    required NodeId id,
    required String name,
    Node$Directory? parent,
  })  : _$id = id,
        _$name = name,
        _$parent =
            parent != null ? WeakReference<Node$Directory>(parent) : null;

  /// Creates a file node
  factory Node.file({
    required NodeId id,
    required String name,
    Node$Directory? parent,
  }) = Node$File;

  /// Creates a directory node
  factory Node.directory({
    required NodeId id,
    required String name,
    Node$Directory? parent,
    List<Node>? children,
  }) = Node$Directory;

  /// Creates a node from a JSON object
  factory Node.fromJson(Object? json) => const NodeFromJsonDecoder()
      .convert(json ?? (throw ArgumentError.notNull('json')));

  /// The unique identifier of the node
  @nonVirtual
  NodeId get id => _$id;
  NodeId _$id;

  /// The name of the node
  @nonVirtual
  String get name => _$name;
  String _$name;

  /// Whether the node is a file
  @nonVirtual
  bool get isFile => !isDirectory;

  /// Whether the node is a directory
  abstract final bool isDirectory;

  /// Whether the node is the root of the tree
  bool get isRoot => _$parent?.target == null;

  /// The parent of the node
  Node$Directory? get parent => _$parent?.target;
  WeakReference<Node$Directory>? _$parent;

  /// Visit the childrens of the node
  void visitChildNodes(NodeVisitor visitor);

  /// Walks the descendant chain and visit all the nodes of the tree
  /// The walk stops when it goes around all the children
  /// or when the callback returns false.
  void visitDescendantNodes(bool Function(Node node) visitor) {
    final q = Queue<Node>();
    visitChildNodes(q.add);
    Node n;
    while (q.isNotEmpty) {
      n = q.removeFirst();
      if (!visitor(n)) return;
      n.visitChildNodes(q.add);
    }
  }

  /// Converts the node to a JSON object
  Object toJson();

  /// Pattern matching
  T map<T>({
    required T Function(Node$File node) file,
    required T Function(Node$Directory node) directory,
  });

  /// Pattern matching with a default case
  T maybeMap<T>({
    T Function(Node$File node)? file,
    T Function(Node$Directory node)? directory,
    required T Function() orElse,
  }) =>
      map<T>(
        file: file ?? (_) => orElse(),
        directory: directory ?? (_) => orElse(),
      );

  /// Pattern matching with a null for the default case
  T? mapOrNull<T>({
    T Function(Node$File node)? file,
    T Function(Node$Directory node)? directory,
  }) =>
      map<T?>(
        file: file ?? (_) => null,
        directory: directory ?? (_) => null,
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Node && id == other.id;

  @override
  String toString() => '$id: $name';
}

/// A file node
class Node$File extends Node {
  Node$File({
    required super.id,
    required super.name,
    super.parent,
  });

  @override
  bool get isDirectory => false;

  @override
  void visitChildNodes(NodeVisitor visitor) {}

  @override
  T map<T>({
    required T Function(Node$File node) file,
    required T Function(Node$Directory node) directory,
  }) =>
      file(this);

  @override
  Object toJson() => const NodeToJsonEncoder().convert(this);
}

/// A directory node
class Node$Directory extends Node {
  Node$Directory({
    required super.id,
    required super.name,
    super.parent,
    List<Node>? children,
  }) : _$children = List<Node>.of(children ?? _emptyChildrenList);

  static final _emptyChildrenList = List<Node>.empty();
  List<Node> get children => UnmodifiableListView<Node>(_$children);
  final List<Node> _$children;

  @override
  bool get isDirectory => true;

  @override
  void visitChildNodes(NodeVisitor visitor) {
    for (final child in _$children) {
      visitor(child);
    }
  }

  @override
  T map<T>({
    required T Function(Node$File node) file,
    required T Function(Node$Directory node) directory,
  }) =>
      directory(this);

  @override
  Object toJson() => const NodeToJsonEncoder().convert(this);

/*   @override
  Map<String, Object?> toJson() {
    final children = <Map<String, Object?>>[];
    Map<String, Object?> dirToJson(
            Node node, List<Map<String, Object?>> children) =>
        <String, Object?>{
          'id': _$id,
          'name': _$name,
          'type': 'dir',
          'children': children,
        };

    final q = Queue<Tuple<List<Map<String, Object?>>, Node>>()
      ..addAll(
        _$children.map<Tuple<List<Map<String, Object?>>, Node>>(
          (e) => Tuple<List<Map<String, Object?>>, Node>(children, e),
        ),
      );
    /* Parent's children list : Node */
    Tuple<List<Map<String, Object?>>, Node> n;
    while (q.isNotEmpty) {
      n = q.removeFirst();
      n.item2.map<void>(
        file: (node) => n.item1.add(node.toJson()),
        directory: (node) {
          final children = <Map<String, Object?>>[];
          n
            ..item1.add(dirToJson(node, children))
            ..item2.visitChildNodes(
              (node) => q.add(
                Tuple<List<Map<String, Object?>>, Node>(children, node),
              ),
            );
        },
      );
    }
    return dirToJson(this, children);
  } */
}

abstract class $NodeChanger {
  /// Alter the properties of a node
  static void change<T extends Node>(
    T node, {
    NodeId? id,
    String? name,
    Node$Directory? parent,
  }) {
    if (id != null) node._$id = id;
    if (name != null) node._$name = name;
    if (parent != null) node._$parent = WeakReference<Node$Directory>(parent);
  }

  static void addChildren(Node$Directory node, List<Node> children) =>
      node._$children.addAll(children);
}
