import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Countries offered for phone numbers, the same list the login screen uses.
const List<Map<String, String>> kCountryCodeOptions = [
  {'name': 'Mauritania', 'code': '+222', 'flag': '🇲🇷'},
  {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
  {'name': 'United Arab Emirates', 'code': '+971', 'flag': '🇦🇪'},
  {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦'},
  {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
  {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
];

/// Display names for [kCountryCodeOptions]; the English 'name' stays as data.
const _countryNameKeys = {
  'Mauritania': 'core_country_mauritania',
  'India': 'core_country_india',
  'United Arab Emirates': 'core_country_uae',
  'Saudi Arabia': 'core_country_saudi_arabia',
  'United States': 'core_country_usa',
  'United Kingdom': 'core_country_uk',
};

/// Opens the country list as a bottom sheet and reports the chosen code and flag.
void showCountryCodePicker({
  required void Function(String code, String flag) onSelected,
}) {
  Get.bottomSheet(
    Material(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'core_country_select'.tr,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kCountryCodeOptions.length,
                  itemBuilder: (context, index) {
                    final country = kCountryCodeOptions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        _countryNameKeys[country['name']]?.tr ??
                            country['name']!,
                        style: GoogleFonts.outfit(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        country['code']!,
                        style: GoogleFonts.outfit(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        onSelected(country['code']!, country['flag']!);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
  );
}
