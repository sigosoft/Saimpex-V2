import 'package:flutter/material.dart';

IconData pharmacySubcategoryIcon(String label) {
  if (label == 'OTC') return Icons.vaccines_rounded;
  if (label == 'Baby Care') return Icons.child_care_rounded;
  if (label == 'Personal Care') return Icons.sanitizer_rounded;
  if (label == 'Dental Care') return Icons.health_and_safety_outlined;
  if (label == 'Wellness') return Icons.spa_rounded;
  if (label == 'Vitamins') return Icons.medication_rounded;
  if (label == 'First Aid') return Icons.medical_services_rounded;
  if (label == 'Device') return Icons.monitor_heart_rounded;
  return Icons.category_rounded;
}
