// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:typed_data';

import 'package:compass/utils/extra.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/loger.dart';
import '../domain/ffe0_controller_repository.dart';

class FFF0Implements extends FFE0Repository{

  static Guid targetService = Guid('fff0');
  static Guid targetChar = Guid('fff1');

  static List<int> deviceInfo = [170, 85, 144, 235, 151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17];
  static List<int> cellInfo = [170, 85, 144, 235, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];
  StreamController<Map<String, dynamic>>? streamController;
  StreamSubscription<dynamic>? charSubscription;
  BluetoothCharacteristic? notifyChar;
  List<int> package = [];

  // 0x90 -> [165, 8, 144, 8, 0, 0, 0, 0, 0, 0, 0, 0, 69]
  // 0x95 -> [165, 8, 149, 8, 0, 0, 0, 0, 0, 0, 0, 0, 74]

  /*
  fff2 - broadcast: false, read: false, writeWithoutResponse: true, write: false, notify: false,
  fff1 - broadcast: false, read: true, writeWithoutResponse: false, write: false, notify: true
  */

  @override
  Future<void> connect(ScanResult r) async {

    List<int> soc = [165, 8, 144, 8, 0, 0, 0, 0, 0, 0, 0, 0, 69];
    List<int> cellVoltage = [0xA5, 0x80, 0x95, 8, 0, 0, 0, 0, 0, 0, 0, 0];

    await r.device.connectAndUpdateStream().then((_) async {

      int calculatedCrc = cellVoltage.sublist(0, cellVoltage.length).reduce((sum, current) => sum + current) & 0xFF;
      cellVoltage.add(calculatedCrc);

      
      List<BluetoothService> services = await r.device.discoverServices();
      log.d(services);

      var service = services.firstWhere((s) => s.uuid == targetService);
      // 43
      var tmpService = services.firstWhere((s) => s.uuid == Guid('f000ffc0-0451-4000-b000-000000000000'));
      var readChar = service.characteristics.firstWhere((c) => c.uuid == Guid('fff1'));
      var writeChar = service.characteristics.firstWhere((c) => c.uuid == Guid('fff2'));
      var tmpChar = tmpService.characteristics.firstWhere((c) => c.uuid == Guid('f000ffc1-0451-4000-b000-000000000000'));

      await tmpChar.write([], withoutResponse: true);
      // List<int> result = await readChar.read();
      // log.d(result);

      Future.delayed(const Duration(seconds: 1));
      await readChar.setNotifyValue(true).then((_) async {
        await writeChar.write(cellVoltage, withoutResponse: true);
        readChar.lastValueStream.listen((value) async {
          log.d('value: $value');
        });
      });
    });
  }

  
  @override
  Future<Stream<Map<String, dynamic>>> streamData(ScanResult r) async {
    streamController = StreamController<Map<String, dynamic>>.broadcast();
    List<BluetoothService> services = await r.device.discoverServices();

    try {
      var service = services.firstWhere((s) => s.uuid == targetService);
      var notifyChar = service.characteristics.firstWhere((c) => c.uuid == targetChar);
      await notifyChar.setNotifyValue(true).then((_) async {
        charSubscription = notifyChar.lastValueStream.listen((value) async {
          if (value[0] == 85){
            if(package.isEmpty){
              package.addAll(value);
            } else {
              Map<String, dynamic> data = decodePackage(package);
              streamController!.add(data);
              package.clear();
              package.addAll(value);
            }
          } else {
            package.addAll(value);
          }
        });
      });
    } catch (e) {
      streamController!.close();
      null;
    }
    return streamController!.stream;
  }

  @override
  Map<String, dynamic> decodePackage(List<int> package) {
    Map<String, dynamic> data = {};
    Uint8List input = Uint8List.fromList(package);
    ByteData bd = input.buffer.asByteData();
    try {
      for (int i = 0; i < 32; i++){
        int result = bd.getInt16(6 + 2 * i, Endian.little);
        result > 0 ? data['cell ${i + 1}'] = '${result / 1000} V' : null;
      }
      int voltage = bd.getInt32(150, Endian.little);
      data['voltage'] = voltage / 1000;
      int power = bd.getInt32(154, Endian.little);
      data['power'] = power / 1000;
      int current = bd.getInt32(158, Endian.little);
      data['current'] = current / 1000;
      int remain = bd.getInt8(173);
      data['remain'] = remain;
      int temp1 = bd.getInt16(162, Endian.little);
      temp1 > 0 ? data['temp 1'] = '${temp1 / 10} °C' : null;
      int temp2 = bd.getInt16(164, Endian.little);
      temp2 > 0 ? data['temp 2'] = '${temp2 / 10} °C' : null;

    } catch (e) {
      null;
    }
    return data;
  }
  
  @override
  void disconnect() {
    notifyChar?.setNotifyValue(false);
    charSubscription?.cancel();
    streamController?.close();
  }
  
}