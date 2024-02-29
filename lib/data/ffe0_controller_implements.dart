

import 'dart:async';
import 'dart:typed_data';

import 'package:compass/utils/extra.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ffe0_controller_repository.dart';
import '../providers/bms_provider.dart';

class FFE0Implements extends FFE0Repository{

  static Guid targetService = Guid('ffe0');
  static Guid targetChar = Guid('ffe1');
  static List<int> deviceInfo = [170, 85, 144, 235, 151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17];
  static List<int> cellInfo = [170, 85, 144, 235, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];
  
  @override
  Future<StreamSubscription?> connect(ScanResult r, WidgetRef ref) async {
    await r.device.connectAndUpdateStream();
    StreamSubscription<dynamic>? charSubscription;
    String mac = r.device.remoteId.str;
    List<int> package = [];
    List<BluetoothService> services = await r.device.discoverServices();
    try {
      var service = services.firstWhere((s) => s.uuid == targetService);
      var char = service.characteristics.firstWhere((c) => c.uuid == targetChar);
      await char.write(deviceInfo, withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 1000));
      await char.setNotifyValue(true).then((_) async {
        await char.write(cellInfo, withoutResponse: false);
        charSubscription = char.lastValueStream.listen((value) async {

          if (value[0] == 85){
            if(package.isEmpty){
              package.addAll(value);
            } else {
              Map currentMonitoring = ref.read(monitoringProvider);
              Uint8List input = Uint8List.fromList(package);
              ByteData bd = input.buffer.asByteData();
              try {
                Map data = {};
                for (int i = 0; i < 32; i++){
                  int result = bd.getInt16(6 + 2 * i, Endian.little);
                  result > 0 ? data['cell ${i + 1}'] = '${result / 1000} V' : null;
                }

                int temp1 = bd.getInt16(162, Endian.little);
                temp1 > 0 ? data['temp1'] = '${temp1 / 10} °C' : null;

                int temp2 = bd.getInt16(164, Endian.little);
                temp2 > 0 ? data['temp2'] = '${temp2 / 10} °C' : null;

                currentMonitoring[mac]['provider'] = Map.from(data);
                ref.read(monitoringProvider.notifier).state = currentMonitoring;

              } catch (e) {
                null;
              }
              package.clear();
              package.addAll(value);
            }
          } else {
            package.addAll(value);
          }
        });
      });
      return charSubscription;
    } catch (e) {
      return null;
    }
  }

}