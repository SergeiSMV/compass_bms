import 'dart:async';
import 'dart:typed_data';

import 'package:compass_bms_app/utils/extra.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/loger.dart';
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
    data['errors'] = [];
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
      data['temp 1'] = '${temp1 ~/ 10} °C';
      int temp2 = bd.getInt16(164, Endian.little);
      data['temp 2'] = '${temp2 ~/ 10} °C';

      // получаем ошибки
      int rawErrorsBitmask = bd.getUint16(166, Endian.little);
      if (rawErrorsBitmask.toRadixString(16) != '0'){
        if (rawErrorsBitmask & 0x0001 != 0) data['errors'].add('Низкая мощность (Low capacity alarm (only warning))');
        if (rawErrorsBitmask & 0x0002 != 0) data['errors'].add('Перегрев МОП-транзистора (MOS tube overtemperature alarm)');
        if (rawErrorsBitmask & 0x0004 != 0) data['errors'].add('Высокое напряжене при зарядке (Charging overvoltage alarm)');
        if (rawErrorsBitmask & 0x0008 != 0) data['errors'].add('Низкое напряжение разряда (Discharge undervoltage alarm)');
        if (rawErrorsBitmask & 0x0010 != 0) data['errors'].add('Перегрев аккумулятора (Battery over temperature alarm)');
        if (rawErrorsBitmask & 0x0020 != 0) data['errors'].add('Перегрузка по току заряда (Charging overcurrent alarm)');
        if (rawErrorsBitmask & 0x0040 != 0) data['errors'].add('Перегрузка по току разряда (Discharge overcurrent alarm)');
        if (rawErrorsBitmask & 0x0080 != 0) data['errors'].add('Перепад напряжения в ячейке (Cell differential pressure alarm)');
        if (rawErrorsBitmask & 0x0100 != 0) data['errors'].add('Перегрев в батарейном отсеке (Overtemperature alarm in battery box)');
        if (rawErrorsBitmask & 0x0200 != 0) data['errors'].add('Низкая температура аккумулятора (Battery low temperature alarm)');
        if (rawErrorsBitmask & 0x0400 != 0) data['errors'].add('Высокое напряжение (Monomer overvoltage alarm)');
        if (rawErrorsBitmask & 0x0800 != 0) data['errors'].add('Низкое напряжение (Monomer undervoltage alarm)');
        if (rawErrorsBitmask & 0x1000 != 0) data['errors'].add('Защита 309_А (309_A protection)');
        if (rawErrorsBitmask & 0x2000 != 0) data['errors'].add('Защита 309_В (309_B protection)');
      }
    } catch (e) {
      null;
    }
    return data;
  }


  

  @override
  // ignore: override_on_non_overriding_member
  Future<void> testData(ScanResult r) async {
    
    List<BluetoothService> services = await r.device.discoverServices();
    var service = services.firstWhere((s) => s.uuid == Guid('f000ffc0-0451-4000-b000-000000000000'));
    var char = service.characteristics.firstWhere((c) => c.uuid == Guid('f000ffc1-0451-4000-b000-000000000000'));

    // List<int> hexRequest = [0x4E, 0x57, 0x00, 0x13, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x68, 0x00, 0x00, 0x01, 0x29];
    // List<int> intRequest = [78, 87, 0, 19, 0, 0, 0, 0, 6, 3, 0, 0, 0, 0, 0, 0, 104, 0, 0, 1, 41];
    // ignore: unused_local_variable
    List<int> hexRequest = [0x4E, 0x57, 0x00, 0x13, 0x00, 0x00, 0x00, 0x00, 0x06, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x68, 0x00, 0x00, 0x01, 0x29];
    List<int> intRequest = [78, 87, 0, 19, 0, 0, 0, 0, 6, 1, 0, 0, 0, 0, 0, 0, 104];

    int calculatedCrc = intRequest.sublist(0, intRequest.length).reduce((sum, current) => sum + current) & 0xFF;
    intRequest.add(calculatedCrc);
    // intRequest.add(calculatedCrc >> 8);
    // intRequest.add(calculatedCrc >> 0);

    log.d('intRequest: $intRequest');

    
    await char.write(intRequest, withoutResponse: false);

    await char.setNotifyValue(true).then((_) async {
      char.lastValueStream.listen((value) async {
        log.d('value: $value');
      });
    });
    
    
  }

  @override
  void disconnect() {
    notifyChar?.setNotifyValue(false);
    charSubscription?.cancel();
    streamController?.close();
  }
  
}