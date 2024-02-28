


import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BluetoothDeviceRepository{

  Future<bool> controlDeviceSevice(BluetoothDevice device);

}