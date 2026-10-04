/// Mirrors backend/functions/src/shared/auth/roles.ts — the custom-claim
/// shape set by admin-bootstrapSuperAdmin / admin-approveVendorApplication.
/// Keep these two in sync by hand; there's no shared-codegen between the
/// Dart and TypeScript sides yet.
enum AppRole { customer, vendor, superAdmin }

class AuthClaims {
  const AuthClaims({required this.role, this.vendorId});

  final AppRole role;
  final String? vendorId;

  factory AuthClaims.fromToken(Map<String, dynamic> claims) {
    final roleStr = claims['role'] as String?;
    final role = switch (roleStr) {
      'vendor' => AppRole.vendor,
      'super_admin' => AppRole.superAdmin,
      _ => AppRole.customer,
    };
    return AuthClaims(role: role, vendorId: claims['vendorId'] as String?);
  }

  static const customer = AuthClaims(role: AppRole.customer);
}
