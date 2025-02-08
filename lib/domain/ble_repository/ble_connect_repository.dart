import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BleConnectRepository {

  Future<void> deviceConnect(WidgetRef ref);

  Future<bool> isDeviceAvailable(WidgetRef ref, String deviceId);

  Future<void> charStreamData(FlutterReactiveBle ble);

  Future<void> disposeStreamDependencies();

}