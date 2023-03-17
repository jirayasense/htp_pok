import 'dart:async';
import 'dart:io';
import 'package:HashtagPoker/core/models/player_model.dart';
import 'package:HashtagPoker/core/models/result.dart';
import 'package:HashtagPoker/core/services/socket_client.dart';
import 'package:HashtagPoker/core/utils/stream_socket.dart';
import 'package:package_info/package_info.dart';

class SocketAuthService {
  Stream<Result<Exception, PlayerModel>> login({
    required String playerFirebaseUid,
    required SocketClient socketClient,
  }) {
    final streamSocket = StreamSocket<Result<Exception, PlayerModel>>();
    socketClient.socket.on("autologinRsp", (data) {
      try {
        final playerModel =
            PlayerModel.fromJson(data['response'] as Map<String, dynamic>);
        streamSocket.addResponse(Result.success(playerModel));
      } catch (_) {
        streamSocket.addResponse(Result.failure(Exception()));
      }
    });

    //HMO-1370 added package version and platform
    PackageInfo.fromPlatform().then((platformValue) => socketClient.socket.emit(
          "auto_login",
          {
            "uid": playerFirebaseUid,
            "playMoney": 1,
            "platform": Platform.isAndroid ? "android" : "ios",
            "ver": platformValue.version
          },
        ));

    return streamSocket.getResponse;
  }
}
