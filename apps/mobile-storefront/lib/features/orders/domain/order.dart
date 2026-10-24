/// Status of a cash-on-delivery order — mirrors backend/functions/src/shared/orders.ts.
enum OrderStatus {
  placed,
  confirmed,
  outForDelivery,
  delivered,
  cancelled;

  static OrderStatus fromWire(String? s) => switch (s) {
        'confirmed' => OrderStatus.confirmed,
        'out_for_delivery' => OrderStatus.outForDelivery,
        'delivered' => OrderStatus.delivered,
        'cancelled' => OrderStatus.cancelled,
        _ => OrderStatus.placed,
      };
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.currency,
    required this.qty,
    required this.lineTotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        productId: j['productId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'USD',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        lineTotal: (j['lineTotal'] as num?)?.toDouble() ?? 0,
      );

  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final String currency;
  final int qty;
  final double lineTotal;
}

/// One order with one vendor (a checkout with several vendors creates one
/// order per vendor).
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.vendorName,
    required this.items,
    required this.totals,
    required this.address,
    required this.note,
    required this.status,
    required this.cancelReason,
    required this.createdAt,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> j) => CustomerOrder(
        id: j['id'] as String,
        vendorName: j['vendorName'] as String? ?? '',
        items: [for (final i in (j['items'] as List? ?? const [])) OrderLine.fromJson(Map<String, dynamic>.from(i as Map))],
        totals: {
          for (final e in (Map<String, dynamic>.from(j['totals'] as Map? ?? const {})).entries)
            e.key: (e.value as num).toDouble(),
        },
        address: j['address'] as String? ?? '',
        note: j['note'] as String? ?? '',
        status: OrderStatus.fromWire(j['status'] as String?),
        cancelReason: j['cancelReason'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch((j['createdAt'] as num?)?.toInt() ?? 0),
      );

  final String id;
  final String vendorName;
  final List<OrderLine> items;
  final Map<String, double> totals;
  final String address;
  final String note;
  final OrderStatus status;
  final String? cancelReason;
  final DateTime createdAt;

  int get itemCount => items.fold(0, (s, i) => s + i.qty);
  bool get canCancel => status == OrderStatus.placed;
}
