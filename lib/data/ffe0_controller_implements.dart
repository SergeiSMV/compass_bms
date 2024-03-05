import 'dart:async';
import 'dart:typed_data';

import 'package:compass/utils/extra.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../domain/ffe0_controller_repository.dart';

class FFE0Implements extends FFE0Repository{

  static Guid targetService = Guid('ffe0');
  static Guid targetChar = Guid('ffe1');
  static List<int> deviceInfo = [170, 85, 144, 235, 151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17];
  static List<int> cellInfo = [170, 85, 144, 235, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];
  StreamController<Map<String, dynamic>>? streamController;
  StreamSubscription<dynamic>? charSubscription;
  BluetoothCharacteristic? notifyChar;
  List<int> package = [];

  @override
  Future<void> connect(ScanResult r) async {
    await r.device.connectAndUpdateStream().then((_) async {
      List<BluetoothService> services = await r.device.discoverServices();
      var service = services.firstWhere((s) => s.uuid == targetService);
      var char = service.characteristics.firstWhere((c) => c.uuid == targetChar);
      await char.write(deviceInfo, withoutResponse: false);
      await Future.delayed(const Duration(milliseconds: 1000));
      await char.write(cellInfo, withoutResponse: false);
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
              // Рассчитываем контрольную сумму для всех элементов списка, кроме последнего
              int calculatedCrc = package.sublist(0, package.length - 1).reduce((sum, current) => sum + current) & 0xFF;
              // Получаем контрольную сумму из последнего элемента списка
              int providedCrc = package.last;
              // Сравниваем рассчитанную контрольную сумму с предоставленной
              bool isCrcValid = calculatedCrc == providedCrc;
              if(isCrcValid){
                Map<String, dynamic> data = decodePackage(package);
                streamController!.add(data);
              } 
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
        result > 0 ? data['cell ${i + 1}'] = result / 1000 : null;
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
      temp1 > 0 ? data['temp 1'] = '${temp1 ~/ 10} °C' : null;
      int temp2 = bd.getInt16(164, Endian.little);
      temp2 > 0 ? data['temp 2'] = '${temp2 ~/ 10} °C' : null;
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