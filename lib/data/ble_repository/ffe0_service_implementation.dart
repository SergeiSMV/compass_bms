import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../domain/ble_repository/ffe0_service_repository.dart';
import '../../static/logger.dart';

class FFE0ServiceImplementation extends FFE0ServiceRepository {

  StreamController<Map<String, dynamic>>? streamController;
  StreamSubscription <List<int>>? charSubscription; 

  @override
  Future<Stream<Map<String, dynamic>>> deviceStreamData(FlutterReactiveBle ble, QualifiedCharacteristic targetCharacteristic) async {

    
    
    try {
      streamController = StreamController<Map<String, dynamic>>.broadcast();
      charSubscription = ble.subscribeToCharacteristic(targetCharacteristic).listen(
        (value) {
          if (value[0] == 85) { // Проверка заголовка пакета
            if (value.isEmpty) {
              value.addAll(value);
            } else {
              int calculatedCrc = value.sublist(0, value.length - 1).reduce((sum, current) => sum + current) & 0xFF;
              int providedCrc = value.last;
              bool isCrcValid = calculatedCrc == providedCrc;
              if (isCrcValid) {
                Map<String, dynamic> data = decodePackage(value);
                streamController!.add(data);
              }
              value.clear();
              value.addAll(value);
            }
          } else {
            value.addAll(value);
          }
        }
      );
    } catch (e) {
      log.e('streamData');
      streamController!.close();
      null;
    }

    return streamController!.stream;
  }


  static Map<String, dynamic> decodePackage(List<int> package) {
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



}



