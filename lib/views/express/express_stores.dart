import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/select_location_controller.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_message.dart';
import '../../core/network/dio_client.dart';
import '../../utils/api_language.dart';
import '../../utils/toast_helper.dart';
import '../grocery/grocery_details_screen.dart';
import '../pharmacy/pharmacy_items_screen.dart';
import '../restaurant_details_screen.dart';
import '../water/water_supplier_details_screen.dart';

/// Express-enabled vendors from customer/expressHome. Express is a delivery
/// option on existing restaurants, groceries, pharmacies and water
/// suppliers, so opening one goes to that vertical's own store screen and
/// orders go through its normal cart and checkout.
class ExpressStores {
  ExpressStores._();

  /// The last loaded vendors, shaped for the express store cards.
  static List<Map<String, String>> stores = const [];

  static const _restaurant = 1;
  static const _grocery = 2;
  static const _pharmacy = 3;
  static const _water = 4;

  static Future<List<Map<String, String>>> load() async {
    if (!Get.isRegistered<DioClient>()) return stores;
    final language = apiLanguageCode();
    try {
      final response = await Get.find<DioClient>().dio.post(
        ApiConstants.expressHome,
        queryParameters: {
          'latitude': SelectLocationController.selectedLatitude,
          'longitude': SelectLocationController.selectedLongitude,
        },
      );
      final envelope = ApiEnvelope.parse(
        response.data,
        language,
        statusCode: response.statusCode,
      );
      final data = asJsonMap(envelope.data) ?? <String, dynamic>{};
      final loaded = <Map<String, String>>[];
      for (final category in (data['categories'] as List? ?? const [])) {
        final group = asJsonMap(category);
        if (group == null) continue;
        final label = '${group['name_en'] ?? ''}';
        for (final vendor in (group['vendors'] as List? ?? const [])) {
          final row = asJsonMap(vendor);
          if (row != null && _verticalEnabled(row['vendor_type'])) {
            loaded.add(_card(row, label));
          }
        }
      }
      loaded.sort(
        (a, b) => (double.tryParse(a['distanceKm']!) ?? 0).compareTo(
          double.tryParse(b['distanceKm']!) ?? 0,
        ),
      );
      stores = loaded;
    } on DioException catch (error) {
      throw ApiException.fromDio(error, language);
    }
    return stores;
  }

  /// Leaves out vendors whose category the admin switched off.
  static bool _verticalEnabled(dynamic vendorType) {
    if (!Get.isRegistered<HomeController>()) return true;
    final slug = switch (int.tryParse('${vendorType ?? ''}')) {
      _restaurant => 'food',
      _grocery => 'grocery',
      _pharmacy => 'pharmacy',
      _water => 'water',
      _ => null,
    };
    return slug == null || Get.find<HomeController>().isVerticalEnabled(slug);
  }

  static Map<String, String> _card(Map<String, dynamic> row, String category) {
    String text(dynamic value) => '${value ?? ''}'.trim();
    final rating = double.tryParse(text(row['rating'])) ?? 0;
    final km = double.tryParse(text(row['distance_km'])) ?? 0;
    final name = text(row['name_en']).isEmpty
        ? text(row['name'])
        : text(row['name_en']);
    final fee = text(row['delivery_price']);
    return {
      'id': text(row['id']),
      'vendorType': text(row['vendor_type']),
      'name': name.isEmpty ? 'st_store'.tr : name,
      'category': category,
      'rating': rating > 0 ? rating.toStringAsFixed(1) : 'st_new'.tr,
      'distanceKm': km.toStringAsFixed(1),
      'dist': 'st_km'.trParams({'km': km.toStringAsFixed(1)}),
      'time': 'st_express'.tr,
      'badgeTime': 'st_express'.tr,
      'points': fee.isEmpty
          ? category
          : 'st_delivery_amount'.trParams({'amount': fee}),
      'image': ApiConstants.mediaUrl(text(row['image'])) ?? '',
    };
  }

  /// Opens the vendor's own store screen for its vertical.
  static void open(Map<String, dynamic> store) {
    final id = int.tryParse('${store['id'] ?? ''}');
    if (id == null) {
      showAppToast('st_store_unavailable'.tr);
      return;
    }
    final name = '${store['name'] ?? ''}';
    final common = <String, dynamic>{
      'id': '$id',
      'vendor_id': id,
      'vendorId': id,
      'name': name,
      'title': name,
      'image': store['image'] ?? '',
      'rating': store['rating'] ?? '',
      'dist': store['dist'] ?? '',
      'time': store['time'] ?? '',
      'discount': '',
      'subtitle': store['category'] ?? '',
      'address': '',
    };
    switch (int.tryParse('${store['vendorType'] ?? ''}')) {
      case _restaurant:
        Get.to(
          () => RestaurantDetailsScreen(
            restaurant: {...common, 'restaurant_id': id},
          ),
        );
      case _grocery:
        Get.to(
          () => GroceryDetailsScreen(store: {...common, 'grocery_id': id}),
        );
      case _pharmacy:
        Get.to(
          () => PharmacyItemsScreen(
            store: {...common, 'isClosed': false, 'isTemporarilyClosed': false},
          ),
        );
      case _water:
        Get.to(() => WaterSupplierDetailsScreen(supplier: common));
      default:
        showAppToast('st_store_unavailable'.tr);
    }
  }
}
