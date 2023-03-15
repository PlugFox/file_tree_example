import 'package:meta/meta.dart';

@immutable
class Tuple<T1, T2> {
  const Tuple(this.item1, this.item2);
  final T1 item1;
  final T2 item2;
}
