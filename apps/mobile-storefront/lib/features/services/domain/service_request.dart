enum ServiceType {
  installation,
  cleaning;

  static ServiceType fromWire(String? s) => s == 'cleaning' ? ServiceType.cleaning : ServiceType.installation;
}

enum ServiceStatus {
  newRequest,
  scheduled,
  completed,
  cancelled;

  static ServiceStatus fromWire(String? s) => switch (s) {
        'scheduled' => ServiceStatus.scheduled,
        'completed' => ServiceStatus.completed,
        'cancelled' => ServiceStatus.cancelled,
        _ => ServiceStatus.newRequest,
      };
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.address,
    required this.preferredDate,
    required this.scheduledFor,
    required this.vendorName,
    required this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> j) {
    DateTime? date(Object? v) => v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
    return ServiceRequest(
      id: j['id'] as String,
      type: ServiceType.fromWire(j['type'] as String?),
      status: ServiceStatus.fromWire(j['status'] as String?),
      address: j['address'] as String? ?? '',
      preferredDate: date(j['preferredDate']),
      scheduledFor: date(j['scheduledFor']),
      vendorName: j['vendorName'] as String?,
      createdAt: date(j['createdAt']) ?? DateTime.now(),
    );
  }

  final String id;
  final ServiceType type;
  final ServiceStatus status;
  final String address;
  final DateTime? preferredDate;
  final DateTime? scheduledFor;
  final String? vendorName;
  final DateTime createdAt;

  bool get canCancel => status == ServiceStatus.newRequest;
}

/// Call-center details (Firestore config/support, set in the admin console).
class SupportInfo {
  const SupportInfo({required this.phone, required this.whatsapp, required this.hours, required this.email});

  final String phone;
  final String whatsapp;
  final String hours;
  final String email;

  bool get isSet => phone.isNotEmpty;
}
