import 'dart:async';
import 'dart:typed_data';

import 'package:compass_bms_app/_old/old_utils/old_extra.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../old_constants/old_loger.dart';
import '../old_domain/old_fff0_controller_repository.dart';

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
  Map<String, dynamic> data = {'errors': []};

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
              data = {'errors': []};
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
    log.d('package: $package');
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
            int volt = bd.getUint16(5 + 2 * i, Endian.big);
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
        data['temp ${i + 1}'] = '${temp - 40} °C';
        // temp > 0 ? data['temp ${i + 1}'] = '${temp - 40} °C' : null;
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
    Uint8List input = Uint8List.fromList(package);
    ByteData bd = input.buffer.asByteData();
    for (int i = 4; i < 12; i++) {
      int byte = bd.getUint8(i);
      if (byte == 0) continue;

      if (i != 11) { // Предполагаем, что Byte7 является 12-м байтом (индекс 11)
        String bits = byte.toRadixString(2).padLeft(8, '0').split('').reversed.join();
        for (int j = 0; j < bits.length; j++) {
          if (bits[j] == '1' && i - 4 < errorDescriptions.length && j < errorDescriptions[i - 4].length) {
            data['errors'].add(errorDescriptions[i - 4][j]);
          }
        }
      }

      if (bd.getUint8(11) == 0x03) {
        data['errors'].add("Fault code: 3");
      }

      /*
      String bits = byte.toRadixString(2).padLeft(8, '0').split('').reversed.join();
      for (int j = 0; j < bits.length; j++) {
        if (bits[j] == '1' && i - 4 < errorDescriptions.length && j < errorDescriptions[i - 4].length) {
          data['errors'].add(errorDescriptions[i - 4][j]);
        }
      }
      */
    }
  }

}


final List<List<String>> errorDescriptions = [
  [
    "Одноступенчатое предупреждение о повышенном напряжении агрегата (One stage warning of unit over voltage)",
    "Одноступенчатое предупреждение о повышенном напряжении агрегата (One stage warning of unit over voltage)",
    "Одноступенчатое предупреждение о повышенном напряжении агрегата (One stage warning of unit over voltage)",
    "Двухступенчатое предупреждение о повышенном напряжении агрегата (Two stage warning of unit over voltage)",
    "Общее напряжение слишком высокое. Первичная тревога (Total voltage is too high One alarm)",
    "Общее напряжение слишком высокое. Тревога второго уровня (Total voltage is too high Level two alarm)",
    "Общее напряжение слишком низкое. Первичная тревога (Total voltage is too low One alarm)",
    "Общее напряжение слишком низкое. Тревога второго уровня (Total voltage is too low Level two alarm)"
  ],
  [
    "Слишком высокая температура зарядки. Первичная тревога (Charging temperature too high. One alarm)",
    "Слишком высокая температура зарядки. Тревога второго уровня (Charging temperature too high. Level two alarm)",
    "Слишком низкая температура зарядки. Первичная тревога (Charging temperature too low. One alarm)",
    "Слишком низкая температура зарядки. Тревога второго уровня (Charging temperature's too low. Level two alarm)",
    "Слишком высокая температура разрядки. Первичная тревога (Discharge temperature is too high. One alarm)",
    "Слишком высокая температура разрядки. Тревога второго уровня (Discharge temperature is too high. Level two alarm)",
    "Слишком низкая температура разрядки. Первичная тревога (Discharge temperature is too low. One alarm)",
    "Слишком низкая температура разрядки. Тревога второго уровня (Discharge temperature is too low. Level two alarm)"
  ],
  [
    "Заряд по току. Тревога первого уровня (Charge over current. Level one alarm)",
    "Заряд по току. Тревога второго уровня (Charge over current, level two alarm)",
    "Разряд по току. Тревога первого уровня (Discharge over current. Level one alarm)",
    "Разряд по току. Тревога второго уровня (Discharge over current, level two alarm)",
    "Уровень заряда батареи превышает допустимые пределы. Тревога первого уровня (SOC is too high an alarm)",
    "Уровень заряда батареи превышает допустимые пределы. Тревога второго уровня (SOC is too high. Alarm Two)",
    "Уровень заряда батареи меньше допустимого предела. Тревога первого уровня (SOC is too low. level one alarm)",
    "Уровень заряда батареи меньше допустимого предела. Тревога второго уровня (SOC is too low. level two alarm)"
  ],
  [
    "Перепад давления. Тревога первого уровня (Excessive differential pressure level one alarm)",
    "Перепад давления. Тревога второго уровня (Excessive differential pressure level two alarm)",
    "Высокий уровень перепада температур. Тревога первого уровня (Excessive temperature difference level one alarm)",
    "Высокий уровень перепада температур. Тревога второго уровня (Excessive temperature difference level two alarm)"
  ],
  [
    "Предупреждение о перегреве зарядного МОП-транзистора (Charging MOS overtemperature warning)"
    "Предупреждение о перегреве разрядного МОП-транзистора (Discharge MOS overtemperature warning)",
    "Отказ датчика определения температуры зарядного МОП-транзистора (Charging MOS temperature detection sensor failure)",
    "Отказ датчика определения температуры разрядного МОП-транзистора (Discharge MOS temperature detection sensor failure)",
    "Нарушение адгезии зарядного МОП-транзистора (Charging MOS adhesion failure)",
    "Нарушение адгезии разрядного МОП-транзистора (Discharge MOS adhesion failure)",
    "Отказ зарядного МОП-транзистора (Charging MOS breaker failure)",
    "Отказ разрядного МОП-транзистора (Discharge MOS breaker failure)"
  ],
  [
    "Неисправность чипа сбора данных AFE (AFE acquisition chip malfunction)",
    "Потеря данных или сигнала от одной или нескольких ячеек (Monomer collect drop off)",
    "Ошибка датчика температуры (Single Temperature Sensor Fault)",
    "Ошибки хранения EEPROM (EEPROM storage failures)",
    "Неисправность часов RTC (RTC clock malfunction)",
    "Ошибка предварительной зарядки (Precharge Failure)",
    "Неисправность автомобильной связи (Vehicle communications malfunction)",
    "Неисправность модуля внутренней связи (Intranet communication module malfunction)"
  ],
  [
    "Cбой текущего модуля (Current Module Failure)",
    "Модуль определения основного давления (Main pressure detection module)",
    "Отказ защиты от короткого замыкания (Short circuit protection failure)",
    "Низкое напряжение, нет зарядки (Low Voltage No Charging)"
  ]
];