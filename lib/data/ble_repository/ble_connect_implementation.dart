import 'dart:async';

import 'package:compass_bms_app/static/keys.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../_old/old_data/old_ffe0_controller_implements.dart';
import '../../domain/ble_repository/ble_connect_repository.dart';
import '../../riverpod/riverpod.dart';
import '../../static/bms_uuids.dart';
import '../../static/logger.dart';
import 'ble_implementation.dart';


class BleConnectImplementation extends BleConnectRepository {
  final DiscoveredDevice device;
  BleConnectImplementation({required this.device}) : super();

  final BleImplementation bleImplementation = BleImplementation(bleImplementationKey);

  // подписка на состояния подключения устройств
  StreamSubscription<ConnectionStateUpdate>? connectSubscription;

  
  @override
  Future<void> deviceConnect(WidgetRef ref) async {

    ref.read(deviceStateProvider(device.id).notifier).updateConnectionStatus(
      loading: true
    );

    final ble = ref.read(bleProvider);

    // Останавливаем сканирование
    bleImplementation.stopScanning();
    ref.read(scanningStateProvider.notifier).stopScan();

    // Отменяем предыдущую подписку, если она есть
    await connectSubscription?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));

    bool available = await isDeviceAvailable(ref, device.id);

    if (available){
      // Подключаемся к устройству
      connectSubscription = ble.connectToDevice(id: device.id).listen(
        (update) {
          switch (update.connectionState) {
            case DeviceConnectionState.connecting:
              break;
            case DeviceConnectionState.connected:
              ref.read(deviceStateProvider(device.id).notifier).updateConnectionStatus(
                device: device,
                isConnected: true,
                loading: false,
                subscription: connectSubscription,
              );
              ref.read(connectedDevicesProvider.notifier).addConnectedDevice(device);
              connected(ble);
              break;
            case DeviceConnectionState.disconnecting:
              break;
            case DeviceConnectionState.disconnected:
              ref.read(deviceStateProvider(device.id).notifier).updateConnectionStatus(
                isConnected: false,
                loading: false,
                subscription: null,
              );
              ref.read(connectedDevicesProvider.notifier).deleteConnectedDevice(device.id);
              break;
          }
        },
        onError: (error) {
          ref.read(messageProvider.notifier).sendMessage(
            'Ошибка при попытке подключения к устройству ${device.id}',
          );
          log.i(error);
        },
      );
    } else {
      ref.read(scannDevicesProvider.notifier).delScannDevice(device);
      ref.read(messageProvider.notifier).sendMessage('подключение к ${device.id} не возможно');
    }
  }


  @override
  Future<bool> isDeviceAvailable(WidgetRef ref, String deviceId) async {
    final ble = ref.read(bleProvider);
    final completer = Completer<bool>();
    final subscription = ble.scanForDevices(withServices: []).listen((device) {
      if (device.id == deviceId) {
        completer.complete(true); // Устройство найдено
      }
    });

    // Таймаут для завершения сканирования
    Future.delayed(const Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        completer.complete(false); // Устройство не найдено
      }
    });

    final result = await completer.future;
    await subscription.cancel();
    Future.delayed(const Duration(milliseconds: 300));
    return result;
  }

  
  connected(FlutterReactiveBle ble) async {
    const List<int> deviceInfo = [170, 85, 144, 235, 151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17];
    const List<int> cellInfo = [170, 85, 144, 235, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16];    
    final services = await ble.getDiscoveredServices(device.id);

    List<int> package = [];
    
    for(var service in services){
      if(serviceUUIDS.contains(service.id)){
        for(var char in service.characteristics){
          if(characteristicUUIDS.contains(char.id)){
            log.i('$char: \nisWritableWithResponse: ${char.isWritableWithResponse}\nisWritableWithoutResponse: ${char.isWritableWithoutResponse}\nisReadable: ${char.isReadable}\nisNotifiable: ${char.isNotifiable}');
            if(char.isWritableWithoutResponse){
              // log.i('сработал isWritableWithoutResponse');
              await char.write(deviceInfo);
              await Future.delayed(const Duration(milliseconds: 1000));
              await char.write(cellInfo);
            } 
            if (char.isNotifiable) {
              // log.i('сработал isNotifiable');
              final QualifiedCharacteristic qualifiedCharacteristic = QualifiedCharacteristic(
                deviceId: device.id,
                serviceId: service.id,
                characteristicId: char.id,
                handle: char.handle
              );

              ble.subscribeToCharacteristic(qualifiedCharacteristic).listen((value){
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
                      Map<String, dynamic> data = FFE0Implements().decodePackage(package);
                      log.i('data: $data');
                    }
                    package.clear();
                    package.addAll(value);
                  }
                } else {
                  package.addAll(value);
                }
              },
              onError: (e) => log.i(e)
              );
            }
          }

          


          /*
          final char = QualifiedCharacteristic(
            deviceId: device.id,
            serviceId: service.id,
            characteristicId: c.id,
          );

          characteristics ??= await ble.resolve(char);
          final characteristicsList = characteristics.toList();
          
          if (characteristicsList.length > 1){
            // Вывод всех найденных характеристик
            for (var resolvedChar in characteristicsList) {
              
              if(resolvedChar.isWritableWithResponse && resolvedChar.isWritableWithoutResponse){
                final writableChar = QualifiedCharacteristic(
                  deviceId: device.id,
                  serviceId: service.id,
                  characteristicId: c.id,
                  handle: resolvedChar.handle
                );
                // await resolvedChar.write(cellInfo, withResponse: false);
                // await ble.writeCharacteristicWithoutResponse(writableChar, value: deviceInfo);
                // await Future.delayed(const Duration(milliseconds: 1000));
                await resolvedChar.write(cellInfo, withResponse: false);
                await Future.delayed(const Duration(milliseconds: 1000));
              }

              else if(resolvedChar.isReadable && resolvedChar.isNotifiable){
                // log.i('characteristic Handle: ${resolvedChar.handle}');
                
                final readableChar = QualifiedCharacteristic(
                  deviceId: device.id,
                  serviceId: service.id,
                  characteristicId: c.id,
                  handle: resolvedChar.handle
                );
                // final value = await ble.readCharacteristic(readableChar);
                // log.i(value);
                ble.subscribeToCharacteristic(readableChar).listen((data){
                  log.i('DATA: $data');
                },
                onError: (e) => log.i(e)
                );
              }
            }
          } else {

            final Characteristic resolvedChar = characteristicsList[0];
            final QualifiedCharacteristic qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: device.id,
              serviceId: service.id,
              characteristicId: resolvedChar.id,
            );
            await resolvedChar.write(deviceInfo, withResponse: false);
            await Future.delayed(const Duration(milliseconds: 1000));
            await resolvedChar.write(cellInfo, withResponse: false);
            await Future.delayed(const Duration(milliseconds: 1000));
            ble.subscribeToCharacteristic(qualifiedCharacteristic).listen((data){
              log.i('DATA: $data');
            },
            onError: (e) => log.i(e)
            );
          }
          */

          
        }
        break;
      }

    }

  }

  
  @override
  Future<void> getDeviceServices(WidgetRef ref, String deviceId) async {
    final ble = ref.read(bleProvider);
    final services = await ble.getDiscoveredServices(deviceId);
    Characteristic targetCharacteristic;

    for(var service in services){
      // есть ли нужный сервис в списке сервисов
      bool aim = serviceUUIDS.contains(service.id);
      
      if (aim){
        targetCharacteristic = service.characteristics.firstWhere(
          (characteristic) => characteristic.isNotifiable,
        );
        // Создание QualifiedCharacteristic
        final qualifiedCharacteristic = QualifiedCharacteristic(
          deviceId: device.id,
          serviceId: service.id,
          characteristicId: targetCharacteristic.id,
        );
        log.i(targetCharacteristic);
      }
      
    }
  }

}
