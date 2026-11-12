import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/service_repository.dart';
import '../../utils/api_language.dart';

/// The top banner of a service vertical's home (car wash, laundry, home
/// cleaning). Shows Admin's first slider image for [vertical]
/// (`customer/serviceHome` → `sliders`) when there is one; otherwise the
/// bundled [asset] artwork from the design. The asset also sets the size,
/// so the layout around the banner doesn't move when the slider loads.
class ServiceBannerImage extends StatelessWidget {
  const ServiceBannerImage({
    super.key,
    required this.vertical,
    required this.asset,
    this.alignment = Alignment.topCenter,
  });

  final String vertical;
  final String asset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          asset,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: alignment,
          errorBuilder: (_, _, _) =>
              Container(height: 240, color: const Color(0xFFFF5216)),
        ),
        if (Get.isRegistered<ServiceRepository>())
          Positioned.fill(
            child: FutureBuilder<ServiceHome>(
              future: Get.find<ServiceRepository>().fetchServiceHome(
                vertical: vertical,
                language: apiLanguageCode(),
              ),
              builder: (context, snapshot) {
                final images = snapshot.data?.sliderImages ?? const [];
                if (images.isEmpty) return const SizedBox.shrink();
                return Image.network(
                  images.first,
                  fit: BoxFit.cover,
                  alignment: alignment,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                );
              },
            ),
          ),
      ],
    );
  }
}
