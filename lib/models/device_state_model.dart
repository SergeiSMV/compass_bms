import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceStateModel {
  final String deviceId;
  final DiscoveredDevice? device;
  final bool isConnected;
  final bool loading;
  final StreamSubscription<ConnectionStateUpdate>? subscription;

  DeviceStateModel({
    required this.deviceId,
    this.device,
    this.isConnected = false,
    this.loading = false,
    this.subscription,
  });

  DeviceStateModel copyWith({
    String? deviceId,
    DiscoveredDevice? device,
    bool? isConnected,
    bool? loading,
    StreamSubscription<ConnectionStateUpdate>? subscription,
  }) {
    return DeviceStateModel(
      deviceId: deviceId ?? this.deviceId,
      device: device ?? this.device,
      isConnected: isConnected ?? this.isConnected,
      loading: loading ?? this.loading,
      subscription: subscription ?? this.subscription,
    );
  }
}
