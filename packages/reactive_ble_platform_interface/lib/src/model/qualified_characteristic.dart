import 'package:meta/meta.dart';

import 'uuid.dart';

/// Specific BLE characteristic for a BLE device characterized by [deviceId], [serviceId] and
/// [characteristicId].
@immutable
class QualifiedCharacteristic {
  /// Unique uuid of the specific characteristic
  final Uuid characteristicId;

  /// Service uuid of the characteristic
  final Uuid serviceId;

  /// Device id of the BLE device
  final String deviceId;

  /// Handle of the BLE device
  final int? handle;

  const QualifiedCharacteristic({
    required this.characteristicId,
    required this.serviceId,
    required this.deviceId,
    this.handle,
  });

  @override
  // default
  // String toString() =>
  //     "$runtimeType(characteristicId: $characteristicId, serviceId: $serviceId, deviceId: $deviceId)";
    String toString() =>
      "$runtimeType(characteristicId: $characteristicId, serviceId: $serviceId, deviceId: $deviceId, handle: ${handle ?? "N/A"})";


  @override
  /// default
  /// int get hashCode => (((17 * 37) + characteristicId.hashCode) * 37 + serviceId.hashCode) * 37 + deviceId.hashCode;
  int get hashCode =>
      deviceId.hashCode ^ serviceId.hashCode ^ characteristicId.hashCode ^ (handle ?? 0).hashCode;

  @override
  bool operator ==(Object other) =>
      other is QualifiedCharacteristic &&
      runtimeType == other.runtimeType &&
      characteristicId == other.characteristicId &&
      serviceId == other.serviceId &&
      deviceId == other.deviceId &&
      handle == other.handle;
}
