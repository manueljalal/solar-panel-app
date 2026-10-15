/// A customer's order as returned by storefront-listMyOrders. One checkout
/// can produce several of these — one per vendor (and currency).
enum OrderStatus {
  placed,
  confirmed,
  installationScheduled,
  installerEnRoute,
  installedVerified,
  cancelled;

  static OrderStatus parse(String? value) => switch (value) {
        'confirmed' => confirmed,
        'installation_scheduled' => installationScheduled,
        'installer_en_route' => installerEnRoute,
        'installed_verified' => installedVerified,
        'cancelled' => cancelled,
        _ => placed,
      };

  String get wire => switch (this) {
        placed => 'placed',
        confirmed => 'confirmed',
        installationScheduled => 'installation_scheduled',
        installerEnRoute => 'installer_en_route',
        installedVerified => 'installed_verified',
        cancelled => 'cancelled',
      };

  /// Steps of the happy path, for the progress timeline.
  static const progression = [placed, confirmed, installationScheduled, installerEnRoute, installedVerified];
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.names,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String productId;
  final String name;
  final Map<String, String> names;
  final String imageUrl;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  String nameFor(String languageCode) {
    final v = names[languageCode == 'ckb' ? 'ku' : languageCode];
    return (v == null || v.isEmpty) ? name : v;
  }

  factory OrderLine.fromJson(Map<String, dynamic> j) {
    final i18n = j['nameI18n'];
    return OrderLine(
      productId: j['productId'] as String? ?? '',
      name: j['name'] as String? ?? '',
      names: i18n is Map ? {for (final e in i18n.entries) '${e.key}': '${e.value}'} : const {},
      imageUrl: j['imageUrl'] as String? ?? '',
      unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (j['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (j['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderStatusChange {
  const OrderStatusChange({required this.status, required this.at, required this.by, required this.note});

  final OrderStatus status;
  final DateTime? at;
  final String by;
  final String note;

  factory OrderStatusChange.fromJson(Map<String, dynamic> j) => OrderStatusChange(
        status: OrderStatus.parse(j['status'] as String?),
        at: _date(j['at']),
        by: j['by'] as String? ?? '',
        note: j['note'] as String? ?? '',
      );
}

DateTime? _date(Object? millis) =>
    millis is num ? DateTime.fromMillisecondsSinceEpoch(millis.toInt()) : null;

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? raw.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.items,
    required this.currency,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.contactName,
    required this.contactPhone,
    required this.addressText,
    required this.city,
    required this.note,
    required this.createdAt,
    required this.history,
    required this.reviewedProductIds,
    required this.disputeStatus,
    required this.disputeResolution,
  });

  final String id;
  final String vendorId;
  final String vendorName;
  final OrderStatus status;
  final List<OrderLine> items;
  final String currency;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String contactName;
  final String contactPhone;
  final String addressText;
  final String city;
  final String note;
  final DateTime? createdAt;
  final List<OrderStatusChange> history;
  final Set<String> reviewedProductIds;

  /// null (never disputed), 'open', 'resolved' or 'rejected'.
  final String? disputeStatus;
  final String? disputeResolution;

  int get itemCount => items.fold(0, (n, l) => n + l.quantity);

  bool get canCancel => status == OrderStatus.placed;
  bool get canConfirmInstallation => status == OrderStatus.installerEnRoute;
  bool get canReview => status == OrderStatus.installedVerified;
  bool get canOpenDispute => disputeStatus != 'open';

  factory CustomerOrder.fromJson(Map<String, dynamic> j) {
    final contact = _map(j['contact']);
    final address = _map(j['address']);
    return CustomerOrder(
      id: j['id'] as String? ?? '',
      vendorId: j['vendorId'] as String? ?? '',
      vendorName: j['vendorName'] as String? ?? '',
      status: OrderStatus.parse(j['status'] as String?),
      items: [for (final i in (j['items'] as List? ?? const [])) OrderLine.fromJson(_map(i))],
      currency: j['currency'] as String? ?? 'USD',
      subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (j['total'] as num?)?.toDouble() ?? 0,
      contactName: contact['name'] as String? ?? '',
      contactPhone: contact['phone'] as String? ?? '',
      addressText: address['text'] as String? ?? '',
      city: address['city'] as String? ?? '',
      note: j['note'] as String? ?? '',
      createdAt: _date(j['createdAt']),
      history: [for (final h in (j['statusHistory'] as List? ?? const [])) OrderStatusChange.fromJson(_map(h))],
      reviewedProductIds: {for (final p in (j['reviewedProductIds'] as List? ?? const [])) '$p'},
      disputeStatus: j['disputeStatus'] as String?,
      disputeResolution: j['disputeResolution'] as String?,
    );
  }
}

/// A quote request and (once the vendor answers) its response.
class QuoteRequestSummary {
  const QuoteRequestSummary({
    required this.id,
    required this.productTitle,
    required this.vendor,
    required this.note,
    required this.status,
    required this.createdAt,
    this.price,
    this.currency,
    this.responseMessage,
  });

  final String id;
  final String productTitle;
  final String vendor;
  final String note;

  /// 'submitted', 'responded' or 'declined'.
  final String status;
  final DateTime? createdAt;
  final double? price;
  final String? currency;
  final String? responseMessage;

  factory QuoteRequestSummary.fromJson(Map<String, dynamic> j) {
    final response = _map(j['response']);
    return QuoteRequestSummary(
      id: j['id'] as String? ?? '',
      productTitle: j['productTitle'] as String? ?? '',
      vendor: j['vendor'] as String? ?? '',
      note: j['note'] as String? ?? '',
      status: j['status'] as String? ?? 'submitted',
      createdAt: _date(j['createdAt']),
      price: (response['price'] as num?)?.toDouble(),
      currency: response['currency'] as String?,
      responseMessage: response['message'] as String?,
    );
  }
}
