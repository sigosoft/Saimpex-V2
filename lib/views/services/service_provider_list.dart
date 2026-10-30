import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/select_location_controller.dart';
import '../../core/network/api_exception.dart';
import '../../models/service_repository.dart';
import '../../utils/api_language.dart';

/// Loads a service vertical's providers near the selected location and
/// builds one card per provider, with loading, empty and error states.
class ServiceProviderList extends StatefulWidget {
  const ServiceProviderList({
    super.key,
    required this.vertical,
    required this.cardBuilder,
    this.emptyText = 'No providers available near you yet',
  });

  final String vertical;
  final Widget Function(Map<String, String> provider) cardBuilder;
  final String emptyText;

  @override
  State<ServiceProviderList> createState() => _ServiceProviderListState();
}

class _ServiceProviderListState extends State<ServiceProviderList> {
  late Future<List<Map<String, String>>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = _load();
  }

  Future<List<Map<String, String>>> _load() {
    if (!Get.isRegistered<ServiceRepository>()) {
      return Future.value(const []);
    }
    return Get.find<ServiceRepository>().fetchProviders(
      vertical: widget.vertical,
      latitude: SelectLocationController.selectedLatitude,
      longitude: SelectLocationController.selectedLongitude,
      language: apiLanguageCode(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: _providers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF5E00)),
            ),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _message(
            error is ApiException ? error.message : 'Could not load providers',
            retry: true,
          );
        }
        final providers = snapshot.data ?? const [];
        if (providers.isEmpty) return _message(widget.emptyText);
        return Column(
          children: [
            for (var i = 0; i < providers.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              widget.cardBuilder(providers[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _message(String text, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFFA59A94),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (retry)
              TextButton(
                onPressed: () => setState(() => _providers = _load()),
                child: Text(
                  'Retry',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFF5E00),
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
