import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` for biometric / device-credential authentication.
class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns `true` when the user has successfully authenticated.
  Future<bool> authenticate() async {
    try {
      final canAuth =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access the Secure Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Check if any biometrics are enrolled on the device.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }
}
