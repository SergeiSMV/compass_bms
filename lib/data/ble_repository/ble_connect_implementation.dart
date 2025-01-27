import 'dart:async';

import 'package:compass_bms_app/static/keys.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    
    for(var service in services){
      if(serviceUUIDS.contains(service.id)){
        for(var c in service.characteristics){
          final qualifiedCharacteristic = QualifiedCharacteristic(
            deviceId: device.id,
            serviceId: service.id,
            characteristicId: c.id,
          );
          final characteristics = await ble.resolve(qualifiedCharacteristic);
          final characteristicsList = characteristics.toList();          
          // Вывод всех найденных характеристик
          for (var resolvedChar in characteristicsList) {
            if(resolvedChar.isWritableWithResponse && resolvedChar.isWritableWithoutResponse){
              try {
                await resolvedChar.write(cellInfo);
              } catch (e) {
                log.e(e);
              }
              await Future.delayed(const Duration(milliseconds: 1000));
            } else if(resolvedChar.isReadable && resolvedChar.isNotifiable){
              try {
                resolvedChar.subscribe().listen((data){
                  log.i(data);
                });
              } catch (e) {
                log.e(e);
              }
            }
          }
        }
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
