import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_settings_controller.dart';
import '../../../../core/widgets/arkan_logo.dart';
import '../controllers/pin_controller.dart';

class PinScreen extends GetView<PinController> {
  const PinScreen({super.key});

  String _title(PinStep s) => switch (s) {
        PinStep.verifyUnlock => 'pin_welcome'.tr,
        PinStep.verifyOld => 'pin_old'.tr,
        PinStep.createNew => 'pin_new'.tr,
        PinStep.confirmNew => 'pin_confirm'.tr,
      };

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: controller.mode == PinMode.change ? AppBar(title: Text('change_pin'.tr)) : null,
      body: SafeArea(
        child: Obx(() {
          final len = controller.input.value.length;
          final err = controller.errorMsg.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(children: [
              const Spacer(),
              const ArkanLogo(size: 68, showBadge: true, badgeIcon: Icons.lock_outline_rounded, showGlow: true),
              const SizedBox(height: 16),
              Text(_title(controller.step.value), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('pin_enter'.tr, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 22),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(AppConstants.pinLength, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: i < len ? 17 : 15, height: i < len ? 17 : 15,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i < len ? scheme.primary : Colors.transparent, border: Border.all(color: err.isNotEmpty ? scheme.error : scheme.primary, width: 2)),
                  )),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(height: 20, child: Text(err, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700, fontSize: 12))),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [for (final row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['theme', '0', 'back']])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row.map((item) {
                        if (item == 'theme') return SizedBox(width: 70, height: 70, child: IconButton(onPressed: () => settings.toggleTheme(), icon: const Icon(Icons.dark_mode_outlined)));
                        if (item == 'back') return SizedBox(width: 70, height: 70, child: IconButton(onPressed: controller.backspace, icon: const Icon(Icons.backspace_outlined)));
                        return SizedBox(width: 70, height: 70, child: OutlinedButton(style: OutlinedButton.styleFrom(shape: const CircleBorder()), onPressed: () => controller.addDigit(item), child: Text(item, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))));
                      }).toList()),
                    )],
                ),
              ),
              const SizedBox(height: 8),
            ]),
          );
        }),
      ),
    );
  }
}