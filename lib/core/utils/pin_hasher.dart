import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

abstract final class PinHasher {
  static String hashPin(String pin) {
    final rng = Random.secure();
    final salt = base64UrlEncode(List<int>.generate(16, (_) => rng.nextInt(256)));
    final digest = sha256.convert(utf8.encode('$salt:$pin')).toString();
    return '$salt:$digest';
  }

  static bool verifyPin(String pin, String payload) {
    final parts = payload.split(':');
    if (parts.length != 2) return false;
    final actual = sha256.convert(utf8.encode('${parts[0]}:$pin')).toString();
    if (actual.length != parts[1].length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ parts[1].codeUnitAt(i);
    }
    return diff == 0;
  }
}