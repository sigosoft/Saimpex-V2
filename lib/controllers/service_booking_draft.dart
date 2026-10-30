/// The provider and catalog service the customer picked on a provider detail
/// screen. The service carts read it when placing the booking, so the ids
/// don't have to be passed through every configure screen in between.
class ServiceBookingDraft {
  ServiceBookingDraft._();

  static String? vertical;
  static int? vendorId;
  static String providerName = '';

  /// The service item exactly as customer/serviceProvider returned it,
  /// including its spaces, addons and garments catalogs.
  static Map<String, dynamic> item = const {};

  static int? get serviceItemId {
    final id = item['id'];
    return id is int ? id : int.tryParse('${id ?? ''}');
  }

  static void select({
    required String vertical,
    required int? vendorId,
    required String providerName,
    required Map<String, dynamic> item,
  }) {
    ServiceBookingDraft.vertical = vertical;
    ServiceBookingDraft.vendorId = vendorId;
    ServiceBookingDraft.providerName = providerName;
    ServiceBookingDraft.item = item;
  }

  static void clear() {
    vertical = null;
    vendorId = null;
    providerName = '';
    item = const {};
  }

  /// Catalog entry names for one list on the item (spaces, addons, garments),
  /// lower-cased. The API rejects names that aren't in the catalog.
  static Set<String> catalogNames(String key) {
    final raw = item[key];
    if (raw is! List) return const {};
    return raw
        .map((entry) => entry is Map ? '${entry['name'] ?? ''}' : '$entry')
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
  }
}
