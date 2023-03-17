import 'dart:async';

import 'package:HashtagPoker/core/app_configs/flavor_config.dart';
import 'package:HashtagPoker/core/auth/socket_auth_service.dart';
import 'package:HashtagPoker/core/models/result.dart';
import 'package:HashtagPoker/core/repositories/player_repository.dart';
import 'package:HashtagPoker/core/utils/stream_socket.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketClient {
  final SocketAuthService socketAuthService;
  final PlayerRepository playerRepository;

  SocketClient({
    required this.socketAuthService,
    required this.playerRepository,
  }) {
    _init();
  }
  late IO.Socket socket;

  void _init() async {
    socket = IO.io(
      FlavorConfig.instance!.values.socketBaseUrl,
      <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'secure': FlavorConfig.isProduction(),
        'query': {
          'token': await FirebaseAuth.instance.currentUser!.getIdToken()
        },
        'autoConnect': false,
      },
    );
    socket.connect();

    connect();
  }

  Stream<Result<Exception, bool>> connect() {
    // this method is used for registeration of events & initially bridging the socket connection
    final streamSocket = StreamSocket<Result<Exception, bool>>();
    if (socket.connected) {
      streamSocket.addResponse(Result.success(true));
    }
    socket.onConnect((data) async {
      final authResult = await socketAuthService
          .login(
            playerFirebaseUid: FirebaseAuth.instance.currentUser!.uid,
            socketClient: this,
          )
          .first;
      authResult.when(
        success: (player) async {
          if (player != null) {
            await playerRepository.cachePlayerModel(player);
            streamSocket.addResponse(Result.success(true));
          }
        },
        failure: (ex) {
          streamSocket.addResponse(Result.failure(Exception("Auth Error")));
        },
      );
    });
    socket.onConnectError((data) {
      streamSocket.addResponse(Result.failure(Exception("Connect Error")));
    });
    socket.onConnectTimeout((data) {
      streamSocket.addResponse(Result.failure(Exception("Connect TimeOut")));
    });
    return streamSocket.getResponse.asBroadcastStream();
  }

  /// Disconnect the current Sockect connection
  bool disconnect() {
    if (socket.connected) {
      socket.disconnect();
      return true;
    }
    return false;
  }

  /// ReConnect the current socket connection if disconnected
  bool reconnect() {
    if (socket.disconnected) {
      socket.connect();
      return true;
    }
    return false;
  }

  void dispose() {
    socket.destroy();
  }
}
