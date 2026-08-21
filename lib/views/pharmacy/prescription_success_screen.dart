import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../my_orders_screen.dart';

class PrescriptionSuccessScreen extends StatelessWidget {
  final String fileName;
  final String? filePath;
  final bool isImage;

  const PrescriptionSuccessScreen({
    super.key,
    required this.fileName,
    this.filePath,
    this.isImage = false,
  });

  String _formatSubmittedAt(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final submittedAt = _formatSubmittedAt(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: Column(
        children: [
          SizedBox(height: topInset + 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withValues(alpha: 0.12),
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
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSuccessCard(context),
                  const SizedBox(height: 12),
                  _buildInfoBanner(),
                  const SizedBox(height: 18),
                  Text(
                    'Order Progress',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProgressCard(submittedAt),
                  const SizedBox(height: 12),
                  _buildTrackCard(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: const Color(0xFFD9CFC6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2C2520),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Get.to(() => const MyOrdersScreen()),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF5E00)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'View Order',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
             
            ),
            child: Image.asset(
              'lib/assets/images/submitted_icon_seal.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Prescription Submitted',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF2C2520),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your prescription has been uploaded successfully. Our pharmacist will review it and prepare your quotation within approximately 5 minutes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF8A7F77),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: isImage &&
                            filePath != null &&
                            File(filePath!).existsSync()
                        ? Image.file(
                            File(filePath!),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.white,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFFF5E00),
                              size: 26,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2C2520),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _openFullPrescription(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Full Prescription',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF5E00),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: Color(0xFFFF5E00),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullPrescription(BuildContext context) {
    if (isImage && filePath != null && File(filePath!).existsSync()) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(filePath!), fit: BoxFit.contain),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF5E00),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening $fileName',
          style: GoogleFonts.outfit(),
        ),
        backgroundColor: const Color(0xFFFF5E00),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8DC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5E00),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'i',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prescription unclear or missing something? The pharmacist will contact you directly to confirm details.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF5A5048),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String submittedAt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const circleSize = 36.0;
                final usable = constraints.maxWidth - circleSize;
                final segment = usable / 3;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: circleSize / 2,
                      right: circleSize / 2,
                      top: (40 - 3) / 2,
                      child: Row(
                        children: [
                          _ProgressConnector(
                            width: segment,
                            style: _ConnectorStyle.halfActive,
                          ),
                          _ProgressConnector(
                            width: segment,
                            style: _ConnectorStyle.inactive,
                          ),
                          _ProgressConnector(
                            width: segment,
                            style: _ConnectorStyle.inactive,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _ProgressCircle(
                          active: true,
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        _ProgressCircle(
                          active: false,
                          child: Image.asset(
                            'lib/assets/images/under_review.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ),
                        _ProgressCircle(
                          active: false,
                          child: Image.asset(
                            'lib/assets/images/quotation_ready.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const _ProgressCircle(
                          active: false,
                          child: Icon(
                            Icons.check_rounded,
                            color: Color(0xFF9AA8B5),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProgressLabel(
                  label: 'Prescription Sent',
                  subtitle: submittedAt,
                  emphasized: true,
                ),
              ),
              const Expanded(
                child: _ProgressLabel(label: 'Under Review'),
              ),
              const Expanded(
                child: _ProgressLabel(label: 'Quotation Ready'),
              ),
              const Expanded(
                child: _ProgressLabel(label: 'Preparing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0EA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFFFF5E00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Your Request',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF2C2520),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can view your prescription status, quotation, and delivery progress anytime from Orders.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6F655D),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ConnectorStyle { halfActive, inactive }

class _ProgressConnector extends StatelessWidget {
  final double width;
  final _ConnectorStyle style;

  const _ProgressConnector({
    required this.width,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = style == _ConnectorStyle.halfActive
        ? const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF5E00),
                Color(0xFFFF5E00),
                Color(0xFFE8DFD6),
                Color(0xFFE8DFD6),
              ],
              stops: [0, 0.48, 0.48, 1],
            ),
            borderRadius: BorderRadius.all(Radius.circular(99)),
          )
        : const BoxDecoration(
            color: Color(0xFFE8DFD6),
            borderRadius: BorderRadius.all(Radius.circular(99)),
          );

    return SizedBox(
      width: width,
      height: 3,
      child: DecoratedBox(decoration: decoration),
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final bool active;
  final Widget child;

  const _ProgressCircle({
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFF5E00) : const Color(0xFFF3EDE7),
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFFFF5E00).withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool emphasized;

  const _ProgressLabel({
    required this.label,
    this.subtitle,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2520),
            fontSize: 11,
            height: 1.25,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.outfit(
              color: const Color(0xFFA59A94),
              fontSize: 8,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
