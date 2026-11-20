class PinVerifyResult {
  const PinVerifyResult({required this.isSuccess, required this.remainingAttempts, required this.lockoutSeconds});
  final bool isSuccess;
  final int remainingAttempts;
  final int lockoutSeconds;
  bool get isLocked => lockoutSeconds > 0;
}

abstract interface class PinRepository {
  Future<bool> hasPin();
  Future<void> savePin(String pin);
  Future<PinVerifyResult> verifyPin(String pin);
  Future<int> getLockoutSeconds();
}