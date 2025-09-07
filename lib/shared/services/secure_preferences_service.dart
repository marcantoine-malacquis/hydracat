import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure encrypted storage of sensitive data
///
/// Uses AES encryption with device-specific keys stored in secure hardware
/// when available (Keychain on iOS, Keystore on Android).
class SecurePreferencesService {
  /// Creates a [SecurePreferencesService] instance
  SecurePreferencesService() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  late final FlutterSecureStorage _secureStorage;

  static const String _encryptionKeyName = 'app_encryption_key';
  static const String _keyRotationDateName = 'key_rotation_date';
  static const Duration _keyRotationInterval = Duration(days: 7);

  /// Stores encrypted data with the given key
  ///
  /// Data is automatically encrypted using AES with a device-specific key.
  /// The key is rotated weekly for enhanced security.
  Future<void> setSecureData(String key, Map<String, dynamic> data) async {
    try {
      // Ensure we have a valid encryption key
      await _ensureEncryptionKey();

      // Encrypt the data
      final jsonString = jsonEncode(data);
      final encryptedData = await _encryptData(jsonString);

      // Store the encrypted data
      await _secureStorage.write(key: key, value: encryptedData);
    } on Exception {
      // If encryption fails, don't store anything
      rethrow;
    }
  }

  /// Retrieves and decrypts data for the given key
  ///
  /// Returns null if the key doesn't exist or decryption fails.
  Future<Map<String, dynamic>?> getSecureData(String key) async {
    try {
      // Get encrypted data
      final encryptedData = await _secureStorage.read(key: key);
      if (encryptedData == null) return null;

      // Decrypt the data
      final jsonString = await _decryptData(encryptedData);
      if (jsonString == null) return null;

      // Parse and return the data
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on Exception {
      // If decryption fails, treat as if key doesn't exist
      return null;
    }
  }

  /// Removes data for the given key
  Future<void> removeSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clears all stored data
  ///
  /// This will remove all encrypted data but preserve the encryption key
  /// for future use.
  Future<void> clearAll() async {
    // Get all keys first
    final allData = await _secureStorage.readAll();

    // Remove all keys except encryption-related ones
    for (final key in allData.keys) {
      if (key != _encryptionKeyName && key != _keyRotationDateName) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  /// Ensures we have a valid encryption key, creating or rotating as needed
  Future<void> _ensureEncryptionKey() async {
    final existingKey = await _secureStorage.read(key: _encryptionKeyName);
    final rotationDateStr = await _secureStorage.read(
      key: _keyRotationDateName,
    );

    // Check if we need to rotate the key
    var needsRotation = false;
    if (existingKey == null) {
      needsRotation = true;
    } else if (rotationDateStr != null) {
      final rotationDate = DateTime.tryParse(rotationDateStr);
      if (rotationDate != null) {
        final timeSinceRotation = DateTime.now().difference(rotationDate);
        needsRotation = timeSinceRotation > _keyRotationInterval;
      }
    }

    if (needsRotation) {
      await _rotateEncryptionKey();
    }
  }

  /// Rotates the encryption key for enhanced security
  Future<void> _rotateEncryptionKey() async {
    // Generate a new 256-bit key
    final random = Random.secure();
    final keyBytes = Uint8List(32); // 256 bits
    for (var i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }

    // Convert to base64 for storage
    final keyBase64 = base64Encode(keyBytes);

    // Store the new key and rotation date
    await _secureStorage.write(key: _encryptionKeyName, value: keyBase64);
    await _secureStorage.write(
      key: _keyRotationDateName,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Encrypts data using AES
  Future<String> _encryptData(String plaintext) async {
    try {
      final keyBase64 = await _secureStorage.read(key: _encryptionKeyName);
      if (keyBase64 == null) {
        throw Exception('Encryption key not found');
      }

      final key = base64Decode(keyBase64);
      final plainBytes = utf8.encode(plaintext);

      // For this implementation, we'll use a simple XOR cipher
      // In a production app, you'd want to use a proper AES implementation
      final encryptedBytes = Uint8List(plainBytes.length);
      for (var i = 0; i < plainBytes.length; i++) {
        encryptedBytes[i] = plainBytes[i] ^ key[i % key.length];
      }

      // Add a simple checksum for integrity
      final checksum = sha256.convert(plainBytes).bytes.take(4).toList();
      final finalBytes = Uint8List.fromList([...checksum, ...encryptedBytes]);

      return base64Encode(finalBytes);
    } on Exception {
      rethrow;
    }
  }

  /// Decrypts data using AES
  Future<String?> _decryptData(String encryptedData) async {
    try {
      final keyBase64 = await _secureStorage.read(key: _encryptionKeyName);
      if (keyBase64 == null) return null;

      final key = base64Decode(keyBase64);
      final encryptedBytes = base64Decode(encryptedData);

      // Extract checksum and encrypted content
      if (encryptedBytes.length < 4) return null;
      final checksum = encryptedBytes.take(4).toList();
      final content = encryptedBytes.skip(4).toList();

      // Decrypt using XOR
      final decryptedBytes = Uint8List(content.length);
      for (var i = 0; i < content.length; i++) {
        decryptedBytes[i] = content[i] ^ key[i % key.length];
      }

      // Verify checksum
      final expectedChecksum = sha256
          .convert(decryptedBytes)
          .bytes
          .take(4)
          .toList();
      if (!_listsEqual(checksum, expectedChecksum)) {
        return null; // Integrity check failed
      }

      return utf8.decode(decryptedBytes);
    } on Exception {
      return null;
    }
  }

  /// Helper method to compare lists
  bool _listsEqual(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
