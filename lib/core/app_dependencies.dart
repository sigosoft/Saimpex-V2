import 'package:get/get.dart';

import '../controllers/select_location_controller.dart';
import 'network/dio_client.dart';
import 'storage/session_store.dart';
import '../models/auth_repository.dart';
import '../models/cart_repository.dart';
import '../models/food_repository.dart';
import '../models/general_repository.dart';
import '../models/grocery_repository.dart';
import '../models/order_repository.dart';
import '../models/pharmacy_repository.dart';
import '../models/profile_repository.dart';
import '../models/courier_repository.dart';
import '../models/service_repository.dart';
import '../models/water_repository.dart';

class AppDependencies {
  static Future<void> init() async {
    final session = SessionStore();
    await session.init();
    Get.put<SessionStore>(session, permanent: true);

    final client = DioClient(session);
    Get.put<DioClient>(client, permanent: true);
    Get.put<AuthRepository>(AuthRepository(client), permanent: true);
    Get.put<ProfileRepository>(ProfileRepository(client), permanent: true);
    Get.put<PharmacyRepository>(PharmacyRepository(client), permanent: true);
    Get.put<CartRepository>(CartRepository(client), permanent: true);
    Get.put<OrderRepository>(OrderRepository(client), permanent: true);
    Get.put<FoodRepository>(FoodRepository(client), permanent: true);
    Get.put<GroceryRepository>(GroceryRepository(client), permanent: true);
    Get.put<WaterRepository>(WaterRepository(client), permanent: true);
    Get.put<CourierRepository>(CourierRepository(client), permanent: true);
    Get.put<ServiceRepository>(ServiceRepository(client), permanent: true);
    Get.put<GeneralRepository>(GeneralRepository(client), permanent: true);
    await SelectLocationController.loadSaved();
  }
}
