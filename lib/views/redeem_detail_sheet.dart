import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RedeemDetailSheet extends StatelessWidget {
  final Map<String, dynamic> reward;

  const RedeemDetailSheet({super.key, required this.reward});

  static Future<void> show(BuildContext context, Map<String, dynamic> reward) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RedeemDetailSheet(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = (reward['store'] ?? 'Al Fantasia').toString();
    final title = (reward['title'] ?? 'Premium Food Basket').toString();
    final subtitle = (reward['subtitle'] ??
            'Reach 5000 points to redeem your basket reward')
        .toString();
    final points = (reward['points'] ?? '5,000 pts').toString();
    final progress = ((reward['progress'] as num?)?.toDouble() ?? 0.6)
        .clamp(0.0, 1.0);
    final redeemable = reward['redeemable'] == true;
    final imageUrl = (reward['image'] ??
            'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800&auto=format&fit=crop')
        .toString();

    final insides = (reward['insides'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const ['Chicken Pasta', 'Chicken Tagine', 'Milk Dessert'];

    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF0EAE3),
                                    child: const Icon(
                                      Icons.card_giftcard_rounded,
                                      size: 40,
                                      color: Color(0xFFA59A94),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        store,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1A1A1A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF8A8A8A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF6F0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'REWARD VALUE',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFA59A94),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Image.asset(
                                          'lib/assets/images/currency.png',
                                          width: 22,
                                          height: 22,
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      (reward['rewardValue'] ??
                                              'Free up to 1,000 MRU')
                                          .toString(),
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFF5E00),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (reward['rewardDescription'] ??
                                              'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.')
                                          .toString(),
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF6B635C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shopping_basket_outlined,
                                    color: Color(0xFFFF5E00),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "What's inside",
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...insides.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF6F0),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5E00),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item,
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF2C2520),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                points,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF5E00),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Stack(
                                    children: [
                                      Container(
                                        height: 8,
                                        width: constraints.maxWidth,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEDE6DF),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      Container(
                                        height: 8,
                                        width:
                                            constraints.maxWidth * progress,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF5E00),
                                              Color(0xFFFFAE00),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: redeemable
                                      ? null
                                      : const Color(0xFFB0B0B0),
                                  gradient: redeemable
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFFF5E00),
                                            Color(0xFFFFAE00),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Text(
                                  'Redeem',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(height: bottomPad + 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8DC),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFFF5E00),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
