import 'dart:async';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/pin_repository.dart';

enum PinMode { verify, change }
enum PinStep { verifyUnlock, verifyOld, createNew, confirmNew }

class PinController extends GetxController {
  PinController(this._repo);
  final PinRepository _repo;
  late final PinMode mode;
  final step = PinStep.verifyUnlock.obs;
  final input = ''.obs;
  final errorMsg = ''.obs;
  final lockoutSeconds = 0.obs;
  String _pending = '';
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    mode = (Get.arguments as PinMode?) ?? PinMode.verify;
    step.value = mode == PinMode.change ? PinStep.verifyOld : PinStep.verifyUnlock;
    _checkLock();
  }

  Future<void> _checkLock() async {
    final s = await _repo.getLockoutSeconds();
    if (s > 0) _startLock(s);
  }

  void addDigit(String d) {
    if (lockoutSeconds.value > 0 || input.value.length >= AppConstants.pinLength) return;
    errorMsg.value = '';
    input.value += d;
    if (input.value.length == AppConstants.pinLength) _submit();
  }

  void backspace() {
    if (input.value.isEmpty) return;
    errorMsg.value = '';
    input.value = input.value.substring(0, input.value.length - 1);
  }

  Future<void> _submit() async {
    if (step.value == PinStep.verifyUnlock || step.value == PinStep.verifyOld) {
      final res = await _repo.verifyPin(input.value);
      if (res.isSuccess) {
        if (step.value == PinStep.verifyOld) { input.value = ''; step.value = PinStep.createNew; }
        else { Get.offAllNamed(AppRoutes.home); }
      } else if (res.isLocked) { input.value = ''; _startLock(res.lockoutSeconds); }
      else { input.value = ''; errorMsg.value = 'pin_wrong'.trParams({'n': '${res.remainingAttempts}'}); }
    } else if (step.value == PinStep.createNew) {
      _pending = input.value; input.value = ''; step.value = PinStep.confirmNew;
    } else {
      if (input.value == _pending) {
        await _repo.savePin(input.value);
        Get.back();
        Get.snackbar('app_title'.tr, 'pin_updated'.tr);
      } else {
        input.value = ''; _pending = ''; step.value = PinStep.createNew; errorMsg.value = 'pin_mismatch'.tr;
      }
    }
  }

  void _startLock(int sec) {
    _timer?.cancel();
    lockoutSeconds.value = sec;
    errorMsg.value = 'pin_locked'.trParams({'s': '$sec'});
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (lockoutSeconds.value <= 1) { t.cancel(); lockoutSeconds.value = 0; errorMsg.value = ''; }
      else { lockoutSeconds.value--; errorMsg.value = 'pin_locked'.trParams({'s': '${lockoutSeconds.value}'}); }
    });
  }

  @override
  void onClose() { _timer?.cancel(); super.onClose(); }
}