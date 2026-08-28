import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showCancelOrderBottomSheet(
  BuildContext context, {
  VoidCallback? onConfirm,
}) {
  int selectedReasonIndex = 0;
  final List<String> cancelReasons = [
    'Changed my mind',
    'Found a better price',
    'Wait time too long',
    'Other',
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main Modal Container
              Container(
                margin: const EdgeInsets.only(top: 48),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7F2),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0EA),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Text(
                        'Cancel Order',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFF5E00),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // Body Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        20 + bottomPad,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why are you cancelling?',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2C2520),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please let us know why you need to cancel this order. Your feedback helps us improve',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8C7D73),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Reasons Radio List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cancelReasons.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final isSelected = selectedReasonIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedReasonIndex = index;
                                  });
                                },
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cancelReasons[index],
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF2C2520),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      // Radio selector button
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFFFF5E00)
                                                : const Color(0xFFEAD8C9),
                                            width: isSelected ? 2 : 1.5,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: isSelected
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF5E00),
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Bottom Action Buttons Row (Cancel & Continue)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6ECE5),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF2C2520),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (onConfirm != null) {
                                      onConfirm();
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Order cancelled successfully',
                                            style: GoogleFonts.outfit(),
                                          ),
                                          backgroundColor:
                                              const Color(0xFFFF5E00),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5E00),
                                          Color(0xFFFFAE00),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF5E00)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Continue',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Close Button (Top Center)
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
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
        },
      );
    },
  );
}
