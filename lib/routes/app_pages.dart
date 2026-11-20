import 'package:get/get.dart';
import '../features/contracts/presentation/screens/contract_detail_screen.dart';
import '../features/contracts/presentation/screens/tenant_detail_screen.dart';
import '../features/home/presentation/bindings/home_binding.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/pin/presentation/bindings/pin_binding.dart';
import '../features/pin/presentation/screens/pin_screen.dart';
import '../features/properties/presentation/screens/property_detail_screen.dart';
import '../features/properties/presentation/screens/unit_detail_screen.dart';
import '../features/splash/presentation/bindings/splash_binding.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen(), binding: SplashBinding()),
    GetPage(name: AppRoutes.pin, page: () => const PinScreen(), binding: PinBinding()),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen(), binding: HomeBinding()),
    GetPage(name: AppRoutes.propertyDetail, page: () => const PropertyDetailScreen()),
    GetPage(name: AppRoutes.unitDetail, page: () => const UnitDetailScreen()),
    GetPage(name: AppRoutes.tenantDetail, page: () => const TenantDetailScreen()),
    GetPage(name: AppRoutes.contractDetail, page: () => const ContractDetailScreen()),
  ];
}