

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/bms_services.dart';
import '../domain/bluetooth_device_repository.dart';

class BluetoothDeviceImplements extends BluetoothDeviceRepository{

  @override
  Future<bool> controlDeviceSevice(BluetoothDevice device) async {
    bool controlResult = false;
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      if (requiredServices.contains(service.uuid.toString())){
        controlResult = true;
        break;
      } else {
        continue;
      }
    }
    return controlResult;
  }

}