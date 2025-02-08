import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../domain/ble_repository/ffe0_service_repository.dart';
import '../../static/bms_uuids.dart';

class FFE0ServiceImplementation extends FFE0ServiceRepository {
  final FlutterReactiveBle ble;
  final String deviceID;
  FFE0ServiceImplementation({required this.ble, required this.deviceID});

  StreamController<Map<String, dynamic>>? streamController;
  StreamSubscription <List<int>>? charSubscription; 

  static const int cellCount = 32;
  static const int voltageOffset = 150;
  static const int powerOffset = 154;
  static const int currentOffset = 158;
  static const int remainOffset = 173;
  static const int temp1Offset = 162;
  static const int temp2Offset = 164;
  static const int errorBitmaskOffset = 166;
  static const List<int> deviceInfo = [170, 85, 144, 235, 151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17];
  static const List<int> cellInfo = [170, 85, 144, 235, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];


  @override
  Future<void> ffe0Connect() async {
    final services = await ble.getDiscoveredServices(deviceID);
    ble.requestMtu(deviceId: deviceID, mtu: 247);
    for (var service in services) {
      if(serviceUUIDS.contains(service.id)){
        for (var char in service.characteristics) {
          if(characteristicUUIDS.contains(char.id)){
            if(char.isWritableWithoutResponse){
              await char.write(deviceInfo);
              await Future.delayed(const Duration(milliseconds: 1000));
              await char.write(cellInfo);
            }
          }
        }
      }
    }
  }

  @override
  Future<Stream<Map<String, dynamic>>> ffe0Stream() async {
    streamController = StreamController<Map<String, dynamic>>.broadcast();
    List<int> package = [];
    final services = await ble.getDiscoveredServices(deviceID);
    for (var service in services) {
      if(serviceUUIDS.contains(service.id)){
        for (var char in service.characteristics) {
          if (char.isNotifiable) {
            final QualifiedCharacteristic qChar = QualifiedCharacteristic(
              deviceId: deviceID,
              serviceId: service.id,
              characteristicId: char.id,
              handle: char.handle
            );
            charSubscription = ble.subscribeToCharacteristic(qChar).listen(
              (value){
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
              }
            );
          }
        }
      }
    }
    return streamController!.stream;
  }


  static Map<String, dynamic> decodePackage(List<int> package) {
    Map<String, dynamic> data = {'errors': []};
    Uint8List input = Uint8List.fromList(package);
    ByteData bd = input.buffer.asByteData();
    try {
      _decodeCells(bd, data);
      _decodeVoltage(bd, data);
      _decodePower(bd, data);
      _decodeCurrent(bd, data);
      _decodeRemain(bd, data);
      _decodeTemperatures(bd, data);
      _decodeErrors(bd, data);
    } catch (_) {
      null;
    }
    return data;
  }

  static void _decodeCells(ByteData bd, Map<String, dynamic> data) {
    for (int i = 0; i < cellCount; i++) {
      int result = bd.getInt16(6 + 2 * i, Endian.little);
      if (result > 0) {
        data['cell ${i + 1}'] = result / 1000;
      }
    }
  }

  static void _decodeVoltage(ByteData bd, Map<String, dynamic> data) {
    int voltage = bd.getInt32(voltageOffset, Endian.little);
    data['voltage'] = voltage / 1000;
  }

  static void _decodePower(ByteData bd, Map<String, dynamic> data) {
    int power = bd.getInt32(powerOffset, Endian.little);
    data['power'] = power / 1000;
  }

  static void _decodeCurrent(ByteData bd, Map<String, dynamic> data) {
    int current = bd.getInt32(currentOffset, Endian.little);
    data['current'] = current / 1000;
  }

  static void _decodeRemain(ByteData bd, Map<String, dynamic> data) {
    int remain = bd.getInt8(remainOffset);
    data['remain'] = remain;
  }

  static void _decodeTemperatures(ByteData bd, Map<String, dynamic> data) {
    int temp1 = bd.getInt16(temp1Offset, Endian.little);
    data['temp 1'] = '${temp1 ~/ 10} °C';
    int temp2 = bd.getInt16(temp2Offset, Endian.little);
    data['temp 2'] = '${temp2 ~/ 10} °C';
  }

  static void _decodeErrors(ByteData bd, Map<String, dynamic> data) {
    int rawErrorsBitmask = bd.getUint16(errorBitmaskOffset, Endian.little);
    if (rawErrorsBitmask != 0) {
      final errorMessages = {
        0x0001: 'Низкая мощность (Low capacity alarm (only warning))',
        0x0002: 'Перегрев МОП-транзистора (MOS tube overtemperature alarm)',
        0x0004: 'Высокое напряжене при зарядке (Charging overvoltage alarm)',
        0x0008: 'Низкое напряжение разряда (Discharge undervoltage alarm)',
        0x0010: 'Перегрев аккумулятора (Battery over temperature alarm)',
        0x0020: 'Перегрузка по току заряда (Charging overcurrent alarm)',
        0x0040: 'Перегрузка по току разряда (Discharge overcurrent alarm)',
        0x0080: 'Перепад напряжения в ячейке (Cell differential pressure alarm)',
        0x0100: 'Перегрев в батарейном отсеке (Overtemperature alarm in battery box)',
        0x0200: 'Низкая температура аккумулятора (Battery low temperature alarm)',
        0x0400: 'Высокое напряжение (Monomer overvoltage alarm)',
        0x0800: 'Низкое напряжение (Monomer undervoltage alarm)',
        0x1000: 'Защита 309_А (309_A protection)',
        0x2000: 'Защита 309_В (309_B protection)',
      };

      errorMessages.forEach((bitmask, message) {
        if (rawErrorsBitmask & bitmask != 0) {
          data['errors'].add(message);
        }
      });
    }
  }

  Future<void> disposeStreamDependencies() async {
    await charSubscription?.cancel();
    await streamController?.close();
  }

}



