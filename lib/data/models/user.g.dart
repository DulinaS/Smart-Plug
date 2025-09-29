// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  tariffSettings: json['tariffSettings'] == null
      ? null
      : TariffSettings.fromJson(json['tariffSettings'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'username': instance.username,
  'displayName': instance.displayName,
  'createdAt': instance.createdAt.toIso8601String(),
  'tariffSettings': instance.tariffSettings,
};

TariffSettings _$TariffSettingsFromJson(Map<String, dynamic> json) =>
    TariffSettings(
      slab1Rate: (json['slab1Rate'] as num).toDouble(),
      slab2Rate: (json['slab2Rate'] as num).toDouble(),
      slab3Rate: (json['slab3Rate'] as num).toDouble(),
      slab4Rate: (json['slab4Rate'] as num).toDouble(),
      fixedCharge: (json['fixedCharge'] as num).toDouble(),
    );

Map<String, dynamic> _$TariffSettingsToJson(TariffSettings instance) =>
    <String, dynamic>{
      'slab1Rate': instance.slab1Rate,
      'slab2Rate': instance.slab2Rate,
      'slab3Rate': instance.slab3Rate,
      'slab4Rate': instance.slab4Rate,
      'fixedCharge': instance.fixedCharge,
    };
