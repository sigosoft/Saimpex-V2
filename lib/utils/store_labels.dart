import 'package:get/get.dart';

/// Store and product card labels (distance, time, offer, points) in the app's
/// language; the numbers come from the API.
String kmLabel(Object value) => 'core_unit_km'.trParams({'value': '$value'});

String minLabel(Object value) => 'core_unit_min'.trParams({'value': '$value'});

String offLabel(Object value) =>
    'core_percent_off'.trParams({'value': '$value'});

String pointsLabel(Object value) =>
    'core_points_available'.trParams({'value': '$value'});
