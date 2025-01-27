import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BleRepository {

  Future<void> startScanning(WidgetRef ref);

  Future<void> stopScanning();

  Future<void> devicesConnectionState(WidgetRef ref);

  Future<void> closeDevicesConnectionState();

}