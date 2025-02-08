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
import 'ffe0_service_implementation.dart';


class BleConnectImplementation extends BleConnectRepository {
  final DiscoveredDevice device;
  BleConnectImplementation({required this.device}) : super();

  final BleImplementation bleImplementation = BleImplementation(bleImplementationKey);

  // подписка на состояния подключения устройств
  StreamSubscription<ConnectionStateUpdate>? connectSubscription;

  // подписка на сканированные устройства
  StreamSubscription<List<int>>? charSubscribtion;

  StreamController<Map<String, dynamic>>? charStreamController;

  
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
              charStreamData(ble);
              // _connectedHandler(ble, device.id);
              break;
            case DeviceConnectionState.disconnecting:
              log.i('Запрос на отключение');
              disposeStreamDependencies();
              break;
            case DeviceConnectionState.disconnected:
              log.i('DeviceConnectionState.disconnected:');
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


  static _connectedHandler(FlutterReactiveBle ble, String deviceID) async {
    final services = await ble.getDiscoveredServices(deviceID);
    for(var service in services){
      if(service.id.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb'){
        FFE0ServiceImplementation(ble: ble, deviceID: deviceID).ffe0Connect();
      }
      if(service.id.toString() == '0000fff0-0000-1000-8000-00805f9b34fb'){
        null;
      }
    }
  }


  @override
  Future<void> charStreamData(FlutterReactiveBle ble) async {

    final services = await ble.getDiscoveredServices(device.id);
    ble.requestMtu(deviceId: device.id, mtu: 247);

    log.i('${device.id} services: $services');
    
    for(var service in services){
      if(serviceUUIDS.contains(service.id)){

        log.i('serviceUUIDS содержит $service');
        log.i('${device.id} characteristics: ${service.characteristics}');

        for(var char in service.characteristics){
          
          if(characteristicUUIDS.contains(char.id)){

            log.i('characteristicUUIDS содержит $char');

          }          
        }
        break;
      }
    }
  }

  /// [Characteristic(0000fff2-0000-1000-8000-00805f9b34fb; 16; 14), Characteristic(0000fff1-0000-1000-8000-00805f9b34fb; 18; 14)] old BMS
  /// 

  @override
  Future<void> disposeStreamDependencies() async {
    await charSubscribtion?.cancel();
    await charStreamController?.close();
    log.i('Отключились! Зависимости удалены!');
  }
  

}
