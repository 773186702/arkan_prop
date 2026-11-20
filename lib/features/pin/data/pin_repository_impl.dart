import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/pin_hasher.dart';
import '../domain/pin_repository.dart';

class PinRepositoryImpl implements PinRepository {
  const PinRepositoryImpl(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasPin() async {
    final h = await _storage.read(key: AppConstants.secPinHash);
    return h != null && h.isNotEmpty;
  }

  @override
  Future<void> savePin(String pin) async {
    await _storage.write(key: AppConstants.secPinHash, value: PinHasher.hashPin(pin));
    await _storage.write(key: AppConstants.secFailed, value: '0');
    await _storage.delete(key: AppConstants.secLockUntil);
  }

  @override
  Future<int> getLockoutSeconds() async {
    final raw = await _storage.read(key: AppConstants.secLockUntil);
    final ms = raw == null ? null : int.tryParse(raw);
    if (ms == null) return 0;
    final sec = DateTime.fromMillisecondsSinceEpoch(ms).difference(DateTime.now()).inSeconds;
    if (sec <= 0) {
      await _storage.delete(key: AppConstants.secLockUntil);
      await _storage.write(key: AppConstants.secFailed, value: '0');
      return 0;
    }
    return sec;
  }

  @override
  Future<PinVerifyResult> verifyPin(String pin) async {
    final locked = await getLockoutSeconds();
    if (locked > 0) return PinVerifyResult(isSuccess: false, remainingAttempts: 0, lockoutSeconds: locked);
    final stored = await _storage.read(key: AppConstants.secPinHash);
    if (stored != null && PinHasher.verifyPin(pin, stored)) {
      await _storage.write(key: AppConstants.secFailed, value: '0');
      await _storage.delete(key: AppConstants.secLockUntil);
      return const PinVerifyResult(isSuccess: true, remainingAttempts: AppConstants.maxPinAttempts, lockoutSeconds: 0);
    }
    final failed = (int.tryParse((await _storage.read(key: AppConstants.secFailed)) ?? '0') ?? 0) + 1;
    if (failed >= AppConstants.maxPinAttempts) {
      await _storage.write(key: AppConstants.secFailed, value: '$failed');
      await _storage.write(key: AppConstants.secLockUntil, value: DateTime.now().add(const Duration(seconds: AppConstants.lockoutSeconds)).millisecondsSinceEpoch.toString());
      return const PinVerifyResult(isSuccess: false, remainingAttempts: 0, lockoutSeconds: AppConstants.lockoutSeconds);
    }
    await _storage.write(key: AppConstants.secFailed, value: '$failed');
    return PinVerifyResult(isSuccess: false, remainingAttempts: AppConstants.maxPinAttempts - failed, lockoutSeconds: 0);
  }
}