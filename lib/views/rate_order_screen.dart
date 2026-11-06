import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/api_exception.dart';
import '../models/order_repository.dart';
import '../models/service_booking_detail.dart' show cleanerPhotoUrl;
import '../utils/rated_orders.dart';
import '../utils/api_language.dart';
import '../utils/toast_helper.dart';
import '../widgets/app_back_button.dart';
import 'rating_reviews_screen.dart';

import '../utils/app_fonts.dart';

class RateOrderScreen extends StatefulWidget {
  final ReviewTarget? reviewTarget;

  /// Numeric order id sent to customer/submitRating.
  final int? orderId;

  /// A service booking: the first card rates the provider, not a restaurant.
  final bool isService;

  /// Service bookings without a delivery driver (car wash, home cleaning,
  /// gas at home) hide the delivery card.
  final bool hasDelivery;

  /// Home cleaning: the booking's assigned cleaner, rated separately.
  final Map<String, dynamic>? cleaner;

  const RateOrderScreen({
    super.key,
    this.reviewTarget,
    this.orderId,
    this.isService = false,
    this.hasDelivery = true,
    this.cleaner,
  });

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  int restaurantRating = 0;
  int deliveryRating = 0;
  int cleanerRating = 0;

  final Set<String> selectedRestaurantTags = {};
  final Set<String> selectedDeliveryTags = {};
  final Set<String> selectedCleanerTags = {};

  final List<String> cleanerTags = [
    'svc_tag_on_time',
    'svc_tag_thorough',
    'svc_tag_friendly',
  ];

  // Translation keys; the comment sent to the server uses the shown text.
  final List<String> restaurantTags = [
    'orders_tag_tasty_food',
    'orders_tag_clean_packaging',
    'orders_tag_good_portion',
  ];
  final List<String> deliveryTags = [
    'orders_tag_fast_delivery',
    'orders_tag_polite',
    'orders_tag_safe_handling',
  ];

  final TextEditingController _reviewController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;
    final orderId = widget.orderId;
    if (orderId == null ||
        orderId < 1 ||
        !Get.isRegistered<OrderRepository>()) {
      showAppToast(
        'orders_cannot_rate'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    if (restaurantRating < 1) {
      showAppToast(
        'orders_rate_store_first'.tr,
        backgroundColor: const Color(0xFFEF4444),
      );
      return;
    }
    String comment(Set<String> tags, String text) =>
        [...tags.map((tag) => tag.tr), if (text.isNotEmpty) text].join(', ');
    // Store and driver tags go in their own fields, in English so they can be
    // counted (CA-23 / C-B17: they were saved inside the comment).
    List<String> tagValues(Set<String> tags) => [
      for (final tag in tags) Get.translations['en']?[tag] ?? tag,
    ];
    setState(() => _submitting = true);
    try {
      final message = await Get.find<OrderRepository>().submitRating(
        orderId: orderId,
        vendorRating: restaurantRating,
        driverRating: deliveryRating,
        vendorComment: _reviewController.text.trim(),
        vendorTags: tagValues(selectedRestaurantTags),
        driverTags: tagValues(selectedDeliveryTags),
        cleanerRating: widget.cleaner == null ? 0 : cleanerRating,
        cleanerComment: comment(selectedCleanerTags, ''),
        language: apiLanguageCode(),
      );
      // My Orders hides the Rate button for this order from now on.
      await RatedOrders.add(orderId);
      if (!mounted) return;
      // Without a store to show reviews for, the reviews screen only said
      // "Reviews are not available here" (C-B16): go back to the list.
      // Leave before the toast: with a snackbar open, Get.back() only
      // closes the snackbar and the form stayed on screen.
      final target = widget.reviewTarget;
      if (target == null) {
        Navigator.of(context).pop(true);
      } else {
        Get.off(() => RatingReviewsScreen(target: target));
      }
      showAppToast(
        message.isEmpty ? 'orders_rating_submitted'.tr : message,
        backgroundColor: const Color(0xFF00B25C),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAppToast(error.message, backgroundColor: const Color(0xFFEF4444));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFFAF6F0),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppBackButton(onTap: () => Navigator.pop(context)),
              ),
              Text(
                'orders_rate_your_order'.tr,
                style: AppFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExperienceCard(
                    imageUrl: '',
                    fallbackAsset: 'lib/assets/images/Food.png',
                    title: widget.isService
                        ? 'svc_rate_provider'.tr
                        : 'orders_rate_restaurant'.tr,
                    rating: restaurantRating,
                    onRatingChanged: (value) {
                      setState(() => restaurantRating = value);
                    },
                    // Food tags (tasty, portion) don't fit a service.
                    tags: widget.isService ? const [] : restaurantTags,
                    selectedTags: selectedRestaurantTags,
                  ),
                  if (widget.cleaner != null) ...[
                    const SizedBox(height: 14),
                    _buildExperienceCard(
                      imageUrl: cleanerPhotoUrl(widget.cleaner!),
                      title: 'svc_rate_cleaner'.trParams({
                        'name': '${widget.cleaner!['name'] ?? ''}'.trim(),
                      }),
                      rating: cleanerRating,
                      onRatingChanged: (value) {
                        setState(() => cleanerRating = value);
                      },
                      tags: cleanerTags,
                      selectedTags: selectedCleanerTags,
                    ),
                  ],
                  if (widget.hasDelivery) ...[
                    const SizedBox(height: 14),
                    _buildExperienceCard(
                      imageUrl: '',
                      fallbackAsset: 'lib/assets/images/delivery_icon.png',
                      title: 'orders_rate_delivery'.tr,
                      rating: deliveryRating,
                      onRatingChanged: (value) {
                        setState(() => deliveryRating = value);
                      },
                      tags: deliveryTags,
                      selectedTags: selectedDeliveryTags,
                    ),
                  ],
                  // Per-item ratings were sample products and were never
                  // sent; the order rating covers the store and delivery.
                  const SizedBox(height: 20),
                  Text(
                    'orders_detailed_review'.tr,
                    style: AppFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      style: AppFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'orders_review_hint'.tr,
                        hintStyle: AppFonts.outfit(
                          color: const Color(0xFFC4B8B0),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).viewPadding.bottom + 12,
            ),
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5216), Color(0xFFFFAE00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5216).withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'orders_submit_rating'.tr,
                  style: AppFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard({
    required String imageUrl,
    String? fallbackAsset,
    required String title,
    required int rating,
    required ValueChanged<int> onRatingChanged,
    required List<String> tags,
    required Set<String> selectedTags,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (fallbackAsset != null) {
                      return Image.asset(
                        fallbackAsset,
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      width: 62,
                      height: 62,
                      color: const Color(0xFFEAD8C9),
                      child: const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStarSelector(
                      rating: rating,
                      onRatingChanged: onRatingChanged,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTags.remove(tag);
                    } else {
                      selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFE8D9)
                        : const Color(0xFFF6EEE8),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: const Color(0xFFFF5216), width: 0.8)
                        : null,
                  ),
                  child: Text(
                    tag.tr,
                    style: AppFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStarSelector({
    required int rating,
    required ValueChanged<int> onRatingChanged,
    double size = 22,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFilled
                  ? const Color(0xFFFFAE00)
                  : const Color(0xFFC8BEB8),
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
