import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_plug/data/repositories/user_device_repo.dart';

@immutable
class UserDeviceView {
  final String deviceId;
  final String deviceName;
  final String? roomName;
  final String? plugType;
  final DateTime createdAt;

  const UserDeviceView({
    required this.deviceId,
    required this.deviceName,
    this.roomName,
    this.plugType,
    required this.createdAt,
  });

  UserDeviceView copyWith({
    String? deviceId,
    String? deviceName,
    String? roomName,
    String? plugType,
    DateTime? createdAt,
  }) {
    return UserDeviceView(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      roomName: roomName ?? this.roomName,
      plugType: plugType ?? this.plugType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class UserDevicesController
    extends StateNotifier<AsyncValue<List<UserDeviceView>>> {
  final UserDeviceRepository _userDeviceRepo;

  UserDevicesController(this._userDeviceRepo)
    : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await _userDeviceRepo.getDevicesForCurrentUser();
      state = AsyncValue.data(
        list
            .map(
              (e) => UserDeviceView(
                deviceId: e.deviceId,
                deviceName: e.deviceName,
                roomName: e.roomName,
                plugType: e.plugType,
                createdAt: e.createdAt,
              ),
            )
            .toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Persisted update (optimistic UI)
  Future<void> updateUserDevice({
    required String deviceId,
    String? deviceName,
    String? roomName,
    String? plugType,
  }) async {
    final prev = state;
    if (state.hasValue) {
      final updated = state.value!
          .map(
            (d) => d.deviceId == deviceId
                ? d.copyWith(
                    deviceName: deviceName ?? d.deviceName,
                    roomName: roomName ?? d.roomName,
                    plugType: plugType ?? d.plugType,
                  )
                : d,
          )
          .toList();
      state = AsyncValue.data(updated);
    }
    try {
      await _userDeviceRepo.updateUserDevice(
        deviceId: deviceId,
        deviceName: deviceName,
        roomName: roomName,
        plugType: plugType,
      );
    } catch (e, st) {
      state = prev;
      rethrow;
    }
  }

  // Persisted unlink (optimistic remove)
  Future<void> unlinkUserDevice(String deviceId) async {
    final prev = state;
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((d) => d.deviceId != deviceId).toList(),
      );
    }
    try {
      await _userDeviceRepo.unlinkUserDevice(deviceId: deviceId);
    } catch (e, st) {
      state = prev;
      rethrow;
    }
  }
}

final userDevicesControllerProvider =
    StateNotifierProvider<
      UserDevicesController,
      AsyncValue<List<UserDeviceView>>
    >((ref) {
      final userDeviceRepo = ref.read(userDeviceRepositoryProvider);
      return UserDevicesController(userDeviceRepo);
    });
