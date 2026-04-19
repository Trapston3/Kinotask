import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/auth_service.dart';

/// Manages vault lock/unlock state. Automatically re-locks when:
///   1. The app goes to [AppLifecycleState.paused].
///   2. The user navigates to another tab (call [lock] manually).
class VaultProvider extends ChangeNotifier with WidgetsBindingObserver {
  VaultProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AuthService _authService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isUnlocked = false;
  bool _isAuthenticating = false;

  bool get isUnlocked => _isUnlocked;
  bool get isAuthenticating => _isAuthenticating;

  /// Retrieves the Hive AES-256 cipher. Generates and stores one if needed.
  Future<HiveAesCipher> getSecureCipher() async {
    final hasKey = await _secureStorage.containsKey(key: 'KinoVaultKey');
    if (!hasKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: 'KinoVaultKey',
        value: base64UrlEncode(key),
      );
    }
    final keyString = await _secureStorage.read(key: 'KinoVaultKey');
    final encryptionKeyUint8List = base64Url.decode(keyString!);
    return HiveAesCipher(encryptionKeyUint8List);
  }

  /// Gracefully opens an encrypted box, migrating it if it currently exists 
  /// without encryption.
  Future<Box> openEncryptedBox(String name) async {
    final cipher = await getSecureCipher();
    try {
      // Trying to open an encrypted box WITHOUT a cipher will successfully throw a HiveError.
      // If it DOESN'T throw, it means the box exists unencrypted (or is empty).
      // We read its contents, delete it, and reopen it with the cipher.
      final tempBox = await Hive.openBox(name);
      
      // If it's a completely new/empty box, let's just add the cipher directly.
      if (tempBox.isEmpty && !tempBox.isOpen) {
         // actually if it didn't throw, it's open.
      }
      
      final data = tempBox.toMap();
      await tempBox.close();
      
      // We must explicitly delete from disk to purge the unencrypted file.
      await Hive.deleteBoxFromDisk(name);

      final newBox = await Hive.openBox(name, encryptionCipher: cipher);
      if (data.isNotEmpty) {
        await newBox.putAll(data);
      }
      return newBox;
    } catch (e) {
      // If we get an exception, it implies the box is ALREADY encrypted.
      // So we just safely open it with the AES cipher.
      return await Hive.openBox(name, encryptionCipher: cipher);
    }
  }

  /// Triggers biometric / credential authentication.
  Future<void> tryUnlock() async {
    if (_isAuthenticating || _isUnlocked) return;
    _isAuthenticating = true;
    notifyListeners();

    final ok = await _authService.authenticate();
    _isUnlocked = ok;
    _isAuthenticating = false;
    notifyListeners();
  }

  /// Force-lock the vault.
  void lock() {
    if (!_isUnlocked) return;
    _isUnlocked = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
