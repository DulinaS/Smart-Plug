import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Billing / plan type for the user account.
enum BillingType { general, enterprise }

extension BillingTypeX on BillingType {
  String toApiString() {
    switch (this) {
      case BillingType.general:
        return 'General';
      case BillingType.enterprise:
        return 'Enterprise';
    }
  }

  static BillingType fromString(String? raw) {
    if (raw == null) return BillingType.general;
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'general':
        return BillingType.general;
      case 'enterprise':
        return BillingType.enterprise;
      case 'enterpise': // tolerate common misspelling
        return BillingType.enterprise;
      default:
        return BillingType.general;
    }
  }
}

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final DateTime createdAt;

  /// Billing type (General / Enterprise)
  @JsonKey(fromJson: _billingFromJson, toJson: _billingToJson)
  final BillingType billingType;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    required this.createdAt,
    required this.billingType,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  static BillingType _billingFromJson(dynamic v) =>
      BillingTypeX.fromString(v?.toString());
  static String _billingToJson(BillingType t) => t.toApiString();

  User copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    DateTime? createdAt,
    BillingType? billingType,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      billingType: billingType ?? this.billingType,
    );
  }
}
