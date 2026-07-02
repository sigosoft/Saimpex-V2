import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingReviewsScreen extends StatefulWidget {
  const RatingReviewsScreen({Key? key}) : super(key: key);

  @override
  State<RatingReviewsScreen> createState() => _RatingReviewsScreenState();
}

class _RatingReviewsScreenState extends State<RatingReviewsScreen> {
  int activeTab = 0; // 0: All Reviews, 1: Most Recent, 2: Highest Rated
  final List<String> tabs = ["All Reviews", "Most Recent", "Highest Rated"];

  final List<Map<String, dynamic>> reviews = [
    {
      "name": "Aicha Mint Ahmed",
      "time": "2 days ago",
      "rating": 5,
      "avatar":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop",
      "text":
          "The Chicken Tagine was absolutely phenomenal! The flavors were perfectly balanced with just the right amount of spice. The service was also top-notch, very attentive staff who made us feel welcome immediately. Definitely coming back for the Pasta next time.",
    },
    {
      "name": "Aicha Mint Ahmed",
      "time": "2 days ago",
      "rating": 5,
      "avatar":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop",
      "text":
          "The Chicken Tagine was absolutely phenomenal! The flavors were perfectly balanced with just the right amount of spice. The service was also top-notch, very attentive staff who made us feel welcome immediately. Definitely coming back for the Pasta next time.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFFFFDF9),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                'Rating & Reviews',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // 1. Rating Overview breakdown card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Left: Average Rating Info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B25C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.6',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Row of stars
                      Row(
                        children: List.generate(5, (index) {
                          final isHalf = index == 4;
                          return Icon(
                            isHalf
                                ? Icons.star_half_rounded
                                : Icons.star_rounded,
                            color: const Color(0xFFFFAE00),
                            size: 14,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '10k+ reviews',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFA59A94),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  // Divider
                  Container(
                    height: 100,
                    width: 0.8,
                    color: const Color(0xFFEAD8C9),
                  ),

                  const SizedBox(width: 20),

                  // Right: Rating Progress Bars
                  Expanded(
                    child: Column(
                      children: [
                        _buildBreakdownRow("5", 0.7, "7,542"),
                        const SizedBox(height: 6),
                        _buildBreakdownRow("4", 0.3, "1,210"),
                        const SizedBox(height: 6),
                        _buildBreakdownRow("3", 0.1, "452"),
                        const SizedBox(height: 6),
                        _buildBreakdownRow("2", 0.05, "190"),
                        const SizedBox(height: 6),
                        _buildBreakdownRow("1", 0.02, "86"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Tabs Horizontal selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (index) {
                final isSelected = activeTab == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      activeTab = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFFFF0EA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF5E00)
                            : Colors.transparent,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: GoogleFonts.outfit(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFFF5E00),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // 3. Reviews list Column
            Column(
              children: reviews.map((rev) => _buildReviewCard(rev)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
    String starLabel,
    double percentage,
    String countText,
  ) {
    return Row(
      children: [
        Text(
          starLabel,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5E00),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            countText,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAD8C9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of reviewer card
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.network(
                  review["avatar"],
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review["name"],
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2C2520),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review["time"],
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFA59A94),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(review["rating"], (index) {
                  return const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFAE00),
                    size: 13,
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Body text of review
          Text(
            review["text"],
            style: GoogleFonts.outfit(
              color: const Color(0xFF7A6A60),
              fontSize: 10.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
