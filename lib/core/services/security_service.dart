import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();

  // In a real production app, this key should be fetched from a secure remote vault or generated per device
  static final _key = encrypt.Key.fromUtf8('my32charultrasecretkeyfornextgen');
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// Encrypts sensitive data like NIDA or Phone Numbers
  static String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts data for internal app use
  static String decryptData(String encryptedBase64) {
    return _encrypter.decrypt64(encryptedBase64, iv: _iv);
  }

  /// Generates a Digital Signature for the ticket to prevent tampering (Fake Tickets)
  /// Uses SHA-256 HMAC
  static String generateTicketHash(String ticketData) {
    var key = utf8.encode('secret-hmac-key-nextgen');
    var bytes = utf8.encode(ticketData);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Securely stores user credentials
  static Future<void> saveSecureValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getSecureValue(String key) async {
    return await _storage.read(key: key);
  }
}
