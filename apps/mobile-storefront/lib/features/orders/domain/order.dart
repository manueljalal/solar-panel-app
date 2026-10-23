import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the server's order lifecycle (backend/functions/src/shared/
/// orders/order_status.ts). Unknown values from a newer backend read as
/// [placed] rather than crashing an older app.
enum OrderStatus {
  placed,
  confirmed,
  shipped,
  delivered,
  cancelled;

  static OrderStatus parse(Object? value) =>
      OrderStatus.values.firstWhere((s) => s.name == value, orElse: () => OrderStatus.placed);
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.names,
    required this.imageUrl,
    required this.unitPrice,
    required this.currency,
    required this.quantity,
    required this.lineTotal,
  });

  final String productId;
  final String name;
  final Map<String, String> names;
  final String imageUrl;
  final double unitPrice;
  final String currency;
  final int quantity;
  final double lineTotal;

  String nameFor(String languageCode) {
    final v = names[languageCode == 'ckb' ? 'ku' : languageCode];
    return (v == null || v.isEmpty) ? name : v;
  }

  factory OrderLine.fromMap(Map<String, dynamic> m) {
    final i18n = m['nameI18n'];
    return OrderLine(
      productId: m['productId'] as String? ?? '',
      name: m['name'] as String? ?? '',
      names: i18n is Map
          ? {for (final e in i18n.entries) if (e.value is String) e.key as String: e.value as String}
          : const {},
      imageUrl: m['imageUrl'] as String? ?? '',
      unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
      currency: m['currency'] as String? ?? 'USD',
      quantity: (m['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (m['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// An `orders/{id}` doc as the customer sees it.
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.lines,
    required this.itemCount,
    required this.totals,
    required this.contactName,
    required this.contactPhone,
    required this.city,
    required this.address,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final OrderStatus status;
  final List<OrderLine> lines;
  final int itemCount;
  final Map<String, double> totals;
  final String contactName;
  final String contactPhone;
  final String city;
  final String address;
  final String note;

  /// Null for a moment right after placing — the server timestamp hasn't
  /// round-tripped yet.
  final DateTime? createdAt;

  /// Short, readable reference for support calls ("Order #K3F9QX").
  String get shortId => shortIdOf(id);

  static String shortIdOf(String id) => (id.length <= 6 ? id : id.substring(0, 6)).toUpperCase();

  bool get canCancel => status == OrderStatus.placed;

  factory CustomerOrder.fromFirestore(String id, Map<String, dynamic> data) {
    final contact = (data['contact'] as Map?)?.cast<String, dynamic>() ?? const {};
    final delivery = (data['delivery'] as Map?)?.cast<String, dynamic>() ?? const {};
    final totals = (data['totals'] as Map?) ?? const {};
    final created = data['createdAt'];
    return CustomerOrder(
      id: id,
      status: OrderStatus.parse(data['status']),
      lines: [
        for (final item in (data['items'] as List?) ?? const [])
          if (item is Map) OrderLine.fromMap(item.cast<String, dynamic>()),
      ],
      itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
      totals: {
        for (final e in totals.entries)
          if (e.value is num) e.key as String: (e.value as num).toDouble(),
      },
      contactName: contact['name'] as String? ?? '',
      contactPhone: contact['phone'] as String? ?? '',
      city: delivery['city'] as String? ?? '',
      address: delivery['address'] as String? ?? '',
      note: delivery['note'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
