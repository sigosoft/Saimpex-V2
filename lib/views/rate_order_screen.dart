import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rating_reviews_screen.dart';

class RateOrderScreen extends StatefulWidget {
  const RateOrderScreen({super.key});

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  int restaurantRating = 0;
  int deliveryRating = 0;
  int item1Rating = 0;
  int item2Rating = 0;

  final Set<String> selectedRestaurantTags = {};
  final Set<String> selectedDeliveryTags = {};

  final List<String> restaurantTags = [
    'Tasty Food',
    'Clean packaging',
    'Good portion size',
  ];
  final List<String> deliveryTags = [
    'Fast Delivery',
    'Polite',
    'Safe Handling',
  ];

  final TextEditingController _reviewController = TextEditingController();

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
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0D6CE),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFFFF5E00),
                      size: 15,
                    ),
                  ),
                ),
              ),
              Text(
                'Rate Your Order',
                style: GoogleFonts.outfit(
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
                    imageUrl:
                        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300&auto=format&fit=crop',
                    title: 'Rate Restaurant Review',
                    rating: restaurantRating,
                    onRatingChanged: (value) {
                      setState(() => restaurantRating = value);
                    },
                    tags: restaurantTags,
                    selectedTags: selectedRestaurantTags,
                  ),
                  const SizedBox(height: 14),
                  _buildExperienceCard(
                    imageUrl:
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&auto=format&fit=crop',
                    fallbackAsset: 'lib/assets/images/delivery_icon.png',
                    title: 'Rate Your Delivery Experience',
                    rating: deliveryRating,
                    onRatingChanged: (value) {
                      setState(() => deliveryRating = value);
                    },
                    tags: deliveryTags,
                    selectedTags: selectedDeliveryTags,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Rate Ordered Items',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildItemRateCard(
                    title: 'Tomato',
                    description: '1Kg',
                    rating: item1Rating,
                    imageUrl:
                        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=350&auto=format&fit=crop',
                    onRatingChanged: (value) {
                      setState(() => item1Rating = value);
                    },
                  ),
                  _buildItemRateCard(
                    title: 'Banana',
                    description: '2 Kg',
                    rating: item2Rating,
                    imageUrl:
                        'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300&auto=format&fit=crop',
                    onRatingChanged: (value) {
                      setState(() => item2Rating = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detailed Review',
                    style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your review here....',
                        hintStyle: GoogleFonts.outfit(
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rating submitted successfully!',
                      style: GoogleFonts.outfit(),
                    ),
                    backgroundColor: const Color(0xFF00B25C),
                  ),
                );
                Get.to(() => const RatingReviewsScreen());
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Submit Rating',
                  style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
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
                        ? Border.all(color: const Color(0xFFFF5E00), width: 0.8)
                        : null,
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
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
            padding: const EdgeInsets.only(right: 6),
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

  Widget _buildItemRateCard({
    required String title,
    required String description,
    required int rating,
    required String imageUrl,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 58,
                height: 58,
                color: const Color(0xFFEAD8C9),
                child: const Icon(Icons.image_outlined, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFEA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x1',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFA59A94),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStarSelector(
                  rating: rating,
                  onRatingChanged: onRatingChanged,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
