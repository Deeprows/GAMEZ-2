import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class RaceMultiplayerClient {
  RaceMultiplayerClient._(this._channel);
  final WebSocketChannel _channel;
  StreamSubscription<dynamic>? _subscription;

  static Future<RaceMultiplayerClient> connect({
    required String endpoint,
    required String playerName,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(Object) onError,
    required void Function() onDisconnected,
  }) async {
    final channel = WebSocketChannel.connect(Uri.parse(endpoint));
    await channel.ready;
    final client = RaceMultiplayerClient._(channel);
    client._subscription = channel.stream.listen((event) {
      try {
        final decoded = jsonDecode(event as String);
        if (decoded is Map<String, dynamic>) onMessage(decoded);
      } catch (error) {
        onError(error);
      }
    }, onError: (Object error) => onError(error), onDone: onDisconnected);
    channel.sink.add(jsonEncode({'type': 'join', 'name': playerName}));
    return client;
  }

  void sendState({required double progress, required double lane, required double speed}) {
    _channel.sink.add(jsonEncode({
      'type': 'state',
      'progress': progress,
      'lane': lane,
      'speed': speed,
    }));
  }

  void sendFinish() {
    _channel.sink.add(jsonEncode({'type': 'finish'}));
  }

  void leave() {
    _channel.sink.add(jsonEncode({'type': 'leave'}));
    close();
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _channel.sink.close();
  }
}
