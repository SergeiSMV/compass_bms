import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BleConnectRepository {

  Future<void> deviceConnect(WidgetRef ref);

  Future<bool> isDeviceAvailable(WidgetRef ref, String deviceId);

  Future<void> getDeviceServices(WidgetRef ref, String deviceId);

}