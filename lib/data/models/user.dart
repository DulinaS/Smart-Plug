import 'package:json_annotation/json_annotation.dart';

part '../user/user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final DateTime createdAt;
  final TariffSettings? tariffSettings;

  const User({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    required this.createdAt,
    this.tariffSettings,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class TariffSettings {
  final double slab1Rate; // 0-30 units
  final double slab2Rate; // 31-60 units
  final double slab3Rate; // 61-90 units
  final double slab4Rate; // 91+ units
  final double fixedCharge;

  const TariffSettings({
    required this.slab1Rate,
    required this.slab2Rate,
    required this.slab3Rate,
    required this.slab4Rate,
    required this.fixedCharge,
  });

  factory TariffSettings.fromJson(Map<String, dynamic> json) =>
      _$TariffSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$TariffSettingsToJson(this);

  // CEB default rates (2024)
  factory TariffSettings.cebDefault() => const TariffSettings(
    slab1Rate: 7.85,
    slab2Rate: 10.00,
    slab3Rate: 27.75,
    slab4Rate: 32.00,
    fixedCharge: 400.00,
  );
}
