import 'dart:async';

class StreamSocket<T> {
  final _socketResponse = StreamController<T>();

  void Function(T) get addResponse => _socketResponse.sink.add;

  Stream<T> get getResponse => _socketResponse.stream;

  bool get isClosed => _socketResponse.isClosed;

  void dispose() {
    _socketResponse.close();
  }
}
