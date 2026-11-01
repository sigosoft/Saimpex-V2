import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/service_booking_draft.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_exception.dart';
import '../../models/general_repository.dart';
import '../../models/service_repository.dart';
import '../../utils/api_language.dart';

/// Loads a provider's catalog services and reviews for the provider detail
/// screens and records the picked service in [ServiceBookingDraft] before
/// configuring it.
mixin ProviderServicesMixin<T extends StatefulWidget> on State<T> {
  List<Map<String, dynamic>> _services = const [];
  bool _servicesLoading = true;
  String? _servicesError;

  String get serviceVertical;
  Map<String, String> get providerCard;

  int? get providerId => int.tryParse(providerCard['id'] ?? '');

  // Vendor types the reviews API takes for each service vertical.
  static const _vendorTypes = {
    ServiceRepository.laundry: 7,
    ServiceRepository.carWash: 8,
    ServiceRepository.homeCleaning: 9,
    ServiceRepository.gas: 10,
  };

  /// Review cards: name, time, rating, avatar, text.
  List<Map<String, dynamic>> providerReviews = const [];
  double reviewAverage = 0;
  int reviewTotal = 0;

  /// One row per star, 5 to 1: star, pct (0–1), count.
  List<Map<String, dynamic>> reviewBreakdown = const [];
  bool reviewsLoading = true;

  /// [filter]: 0 all, 1 most recent, 2 highest rated.
  Future<void> loadProviderReviews([int filter = 0]) async {
    final id = providerId;
    if (id == null || !Get.isRegistered<GeneralRepository>()) {
      setState(() => reviewsLoading = false);
      return;
    }
    setState(() => reviewsLoading = true);
    try {
      final result = await Get.find<GeneralRepository>().fetchReviews(
        type: 'provider',
        language: apiLanguageCode(),
        vendorId: id,
        vendorType: _vendorTypes[serviceVertical],
        filter: const ['', 'most_recent', 'highest_rated'][filter],
      );
      if (!mounted) return;
      final total = result.totalReviews;
      setState(() {
        reviewAverage = result.averageRating;
        reviewTotal = total;
        reviewBreakdown = [
          for (final star in ['5', '4', '3', '2', '1'])
            {
              'star': star,
              'pct': total == 0
                  ? 0.0
                  : (result.ratingBreakdown[star] ?? 0) / total,
              'count': '${result.ratingBreakdown[star] ?? 0}',
            },
        ];
        providerReviews = [
          for (final review in result.reviews)
            {
              'name': review['userName'],
              'time': review['timeAgo'].toString().isEmpty
                  ? review['date']
                  : review['timeAgo'],
              'rating': review['rating'],
              'avatar': review['userImage'],
              'text': review['comment'],
            },
        ];
      });
    } on ApiException {
      // The tab shows "No reviews yet" when they can't load.
    } finally {
      if (mounted) setState(() => reviewsLoading = false);
    }
  }

  Future<void> loadProviderServices() async {
    final id = providerId;
    if (id == null || !Get.isRegistered<ServiceRepository>()) {
      setState(() => _servicesLoading = false);
      return;
    }
    setState(() {
      _servicesLoading = true;
      _servicesError = null;
    });
    try {
      final data = await Get.find<ServiceRepository>().fetchProvider(
        vendorId: id,
        language: apiLanguageCode(),
      );
      if (!mounted) return;
      setState(
        () => _services = data['services'] as List<Map<String, dynamic>>,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _servicesError = error.message);
    } finally {
      if (mounted) setState(() => _servicesLoading = false);
    }
  }

  /// A catalog service shaped like the screens' service cards. `apiIndex`
  /// points back at the raw item for [selectService].
  Map<String, String> serviceCard(int index, {String fallbackImage = ''}) {
    final row = _services[index];
    String text(dynamic value) => '${value ?? ''}'.trim();
    final image = ApiConstants.mediaUrl(text(row['image'])) ?? fallbackImage;
    final unit = text(row['unit']).toLowerCase();
    return {
      'apiIndex': '$index',
      'title': text(row['name_en']).isEmpty
          ? text(row['name'])
          : text(row['name_en']),
      'description': text(row['description_en']).isEmpty
          ? text(row['description'])
          : text(row['description_en']),
      'price': text(row['starting_rate']),
      'duration': text(row['processing_label']).isEmpty
          ? text(row['duration'])
          : text(row['processing_label']),
      'image': image,
      'isNetwork': image.startsWith('http') ? 'true' : 'false',
      'action': unit == 'piece' || unit == 'item' ? 'View Prices' : 'ADD',
    };
  }

  /// Remembers the picked service for the cart's booking request.
  void selectService(Map<String, String> card) {
    final index = int.tryParse(card['apiIndex'] ?? '');
    if (index == null || index < 0 || index >= _services.length) return;
    ServiceBookingDraft.select(
      vertical: serviceVertical,
      vendorId: providerId,
      providerName: providerCard['name'] ?? '',
      item: _services[index],
    );
  }

  /// Builds the services list, or a loading / empty / error state.
  Widget buildProviderServices(
    Widget Function(Map<String, String> card) itemBuilder, {
    String fallbackImage = '',
  }) {
    final Widget child;
    if (_servicesLoading) {
      child = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
        ),
      );
    } else if (_servicesError != null || _services.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Text(
              _servicesError ?? 'svc_provider_no_services'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_servicesError != null)
              TextButton(
                onPressed: loadProviderServices,
                child: Text(
                  'retry'.tr,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      child = Column(
        children: [
          for (var i = 0; i < _services.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            itemBuilder(serviceCard(i, fallbackImage: fallbackImage)),
          ],
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: child,
    );
  }
}
