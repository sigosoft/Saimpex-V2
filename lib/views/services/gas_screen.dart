import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/service_repository.dart';
import '../../widgets/app_back_button.dart';
import 'gas_order_screen.dart';
import 'provider_services_mixin.dart';
import 'service_provider_list.dart';

/// Gas: suppliers near the delivery location (customer/serviceProviders,
/// vertical gas). No Figma screen exists for gas, so this follows the other
/// service screens' style.
class GasScreen extends StatelessWidget {
  const GasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _GasHeader(title: 'gas_title'.tr),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: _ExchangeNote(text: 'gas_exchange_intro'.tr),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ServiceProviderList(
                vertical: ServiceRepository.gas,
                emptyText: 'gas_no_suppliers'.tr,
                cardBuilder: (provider) => _SupplierCard(provider: provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One supplier's gas products (refills, new cylinders) with prices.
class GasProviderScreen extends StatefulWidget {
  const GasProviderScreen({super.key, required this.provider});

  final Map<String, String> provider;

  @override
  State<GasProviderScreen> createState() => _GasProviderScreenState();
}

class _GasProviderScreenState extends State<GasProviderScreen>
    with ProviderServicesMixin<GasProviderScreen> {
  @override
  String get serviceVertical => ServiceRepository.gas;

  @override
  Map<String, String> get providerCard => widget.provider;

  @override
  void initState() {
    super.initState();
    loadProviderServices();
  }

  void _order(Map<String, String> card) {
    selectService(card);
    Get.to(
      () => GasOrderScreen(
        providerName: widget.provider['name'] ?? '',
        productTitle: card['title'] ?? '',
        productImage: card['image'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _GasHeader(title: widget.provider['name'] ?? 'gas_title'.tr),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'gas_choose_product'.tr,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2C2520),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            buildProviderServices(
              (card) => _ProductCard(card: card, onTap: () => _order(card)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GasHeader extends StatelessWidget {
  const _GasHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          AppBackButton(onTap: () => Get.back()),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: const Color(0xFF2C2520),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

/// The empty-cylinder rule, shown before the customer picks anything.
class _ExchangeNote extends StatelessWidget {
  const _ExchangeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.propane_tank_outlined,
            color: Color(0xFFFF5E00),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: const Color(0xFF5A4A40),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.provider});

  final Map<String, String> provider;

  @override
  Widget build(BuildContext context) {
    final image = provider['image'] ?? '';
    final distance = provider['distance'] ?? '';
    final from = provider['price1'] ?? '';
    return GestureDetector(
      onTap: () => Get.to(() => GasProviderScreen(provider: provider)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _Thumb(url: image, size: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFF5E00),
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(provider['rating'] ?? '', style: _metaStyle),
                      if (distance.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFFF5E00),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(distance, style: _metaStyle),
                      ],
                    ],
                  ),
                  if (from.isNotEmpty && from != '—') ...[
                    const SizedBox(height: 6),
                    Text(
                      'gas_from_price'.trParams({'price': from}),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF5E00),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFA59A94)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.card, required this.onTap});

  final Map<String, String> card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = card['description'] ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _Thumb(url: card['image'] ?? '', size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['title'] ?? '',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2C2520),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF7A6A60),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    card['price'] ?? '',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFF5E00),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5E00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'gas_order'.tr,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: const Color(0xFFFFF0E5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.propane_tank_rounded,
        color: Color(0xFFFF5E00),
        size: 30,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url.startsWith('http')
          ? Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}

final _metaStyle = GoogleFonts.outfit(
  color: const Color(0xFF4A453F),
  fontSize: 11.5,
  fontWeight: FontWeight.w500,
);
