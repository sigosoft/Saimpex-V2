import 'package:get/get.dart';

import 'network/dio_client.dart';
import 'storage/session_store.dart';
import '../models/auth_repository.dart';
import '../models/profile_repository.dart';

class AppDependencies {
  static Future<void> init() async {
    final session = SessionStore();
    await session.init();
    Get.put<SessionStore>(session, permanent: true);

    final client = DioClient(session);
    Get.put<DioClient>(client, permanent: true);
    Get.put<AuthRepository>(AuthRepository(client), permanent: true);
    Get.put<ProfileRepository>(ProfileRepository(client), permanent: true);
  }
}
