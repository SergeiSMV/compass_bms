import 'dart:async';
import 'dart:typed_data';

import 'package:compass/utils/extra.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/loger.dart';
import '../domain/fff0_controller_repository.dart';

class FFF0Implements extends FFF0Repository{
  
  static Guid tmpServiceGuid = Guid('f000ffc0-0451-4000-b000-000000000000');
  static Guid tmpCharGuid = Guid('f000ffc1-0451-4000-b000-000000000000');
  static Guid mainServiceGuid = Guid('fff0');
  static Guid readCharGuid = Guid('fff1');
  static Guid writeCharGuid = Guid('fff2');
  static List<int> cellVoltageRequest = [0xA5, 0x80, 0x95, 8, 0, 0, 0, 0, 0, 0, 0, 0];
  static List<int> temperatureRequest = [0xA5, 0x80, 0x96, 8, 0, 0, 0, 0, 0, 0, 0, 0];
  static List<int> socRequest = [0xA5, 0x80, 0x90, 8, 0, 0, 0, 0, 0, 0, 0, 0];
  static List<int> errorRequest = [0xA5, 0x80, 0x98, 8, 0, 0, 0, 0, 0, 0, 0, 0];
  static List requests = [cellVoltageRequest, temperatureRequest, socRequest, errorRequest];

  BluetoothCharacteristic? notifyChar;
  StreamSubscription<dynamic>? charSubscription;
  StreamController<Map<String, dynamic>>? streamController;
  Map<String, dynamic> data = {};

  @override
  Future<void> connect(ScanResult r) async {
    await r.device.connectAndUpdateStream().then((_) async {
      List<BluetoothService> services = await r.device.discoverServices();
      var tmpService = services.firstWhere((s) => s.uuid == tmpServiceGuid);
      var tmpChar = tmpService.characteristics.firstWhere((c) => c.uuid == tmpCharGuid);
      // touch устройтсво
      await tmpChar.write([], withoutResponse: false);
      Future.delayed(const Duration(seconds: 1));
    });
  }

  @override
  Future<Stream<Map<String, dynamic>>> streamData(ScanResult r) async {

    int reqIndex = 0;

    streamController = StreamController<Map<String, dynamic>>.broadcast();
    List<BluetoothService> services = await r.device.discoverServices();

    var service = services.firstWhere((s) => s.uuid == mainServiceGuid);
    var notifyChar = service.characteristics.firstWhere((c) => c.uuid == readCharGuid);
    var writeChar = service.characteristics.firstWhere((c) => c.uuid == writeCharGuid);

    for(var req in requests){
      int crc = calculatedCrc(req);
      req.add(crc);
    }

    await writeChar.write(requests[reqIndex], withoutResponse: true).then((_) => reqIndex++);

    try {
      await notifyChar.setNotifyValue(true).then((_) async {
        charSubscription = notifyChar.lastValueStream.listen((package) async {
          if (package.isNotEmpty){
            if (package[2] == 149 && data.isNotEmpty){
              streamController!.add(data);
              data = {};
              decodePackage(package);
            } else {
              decodePackage(package);
            }

            if (reqIndex > requests.length - 1){
              reqIndex = 0;
              await writeChar.write(requests[reqIndex], withoutResponse: true).then((_) => reqIndex++);
            } else {
              await writeChar.write(requests[reqIndex], withoutResponse: true).then((_) => reqIndex++);
            }
          }
        });
      });
    } catch (e) {
      streamController!.close();
    }

    return streamController!.stream;

  }

  @override
  void decodePackage(List<int> package) {
    if (package[0] == 165 && package[1] == 1){
      switch(package[2]){
        case 149: // Cell voltage 1~48
          decodeCellVoltage(package);
          break;
        case 150: // Monomer temperature 1~16
          decodeTemperature(package);
          break;
        case 144: // SOC of Total Voltage Current
          decodeSOC(package);
          break;
        case 152: // Battery failure status
          decodeError(package);
          break;
        default:
          log.d('default package: $package');
          break;
      }
    } else {
      null;
    }
  }
  
  @override
  void disconnect() {
    notifyChar?.setNotifyValue(false);
    charSubscription?.cancel();
    streamController?.close();
  }

  @override
  int calculatedCrc(List<int> requestData) {
    return requestData.sublist(0, requestData.length).reduce((sum, current) => sum + current) & 0xFF;
  }
  
  @override
  void decodeCellVoltage(List<int> package) {

    List<int> cellValues = [];
    List<List<int>> chunks = [];
    int chunkSize = 13;
    for (int i = 0; i < package.length; i += chunkSize) {
      int end = (i + chunkSize < package.length) ? i + chunkSize : package.length;
      List<int> chunk = package.sublist(i, end);
      chunks.add(chunk);
    }

    for (var chunk in chunks){
      if (chunk[0] == 165 && chunk[4] != 0){
        Uint8List input = Uint8List.fromList(chunk);
        ByteData bd = input.buffer.asByteData();
        for (int i = 0; i < 3; i++){
          try {
            int volt = bd.getInt16(4 + 2 * i, Endian.little);
            cellValues.add(volt);
          } catch (e) {
            null;
            break;
          }
        }
      } else {
        continue;
      }
    }

    for (int i = 0; i < cellValues.length; i++){
      data['cell ${i + 1}'] = cellValues[i] / 1000;
    }
  }
  
  @override
  void decodeTemperature(List<int> package) {
    Uint8List input = Uint8List.fromList(package);
    ByteData bd = input.buffer.asByteData();
    for (int i = 0; i < 7; i++){
      try {
        int temp = bd.getInt8(5 + 1 * i);
        temp > 0 ? data['temp ${i + 1}'] = '${temp - 40} °C' : null;
      } catch (e) {
        null;
        break;
      }
    }
  }

  @override
  void decodeSOC(List<int> package) {
    // [165, 1, 144, 8, 0, 145, 0, 0, 117, 48, 3, 232, 95]
    Uint8List input = Uint8List.fromList(package);
    ByteData bd = input.buffer.asByteData();

    int voltage = bd.getInt16(4, Endian.big);
    data['voltage'] = voltage / 10;

    int current = bd.getInt16(8, Endian.big);
    data['current'] = (current - 30000) / 10;

    int remain = bd.getInt16(10, Endian.big);
    data['remain'] = remain ~/ 10;
  }
  
  @override
  void decodeError(List<int> package) {
    
  }

}