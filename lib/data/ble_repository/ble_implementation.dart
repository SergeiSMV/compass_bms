import 'dart:async';

import 'package:compass_bms_app/domain/ble_repository/ble_repository.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpod/riverpod.dart';
import '../../static/bms_uuids.dart';
import '../../static/logger.dart';

class BleImplementation extends BleRepository {

  static final Map<String, BleImplementation> _instances = {};

  final String key;
  // подписка на сканированные устройства
  StreamSubscription<DiscoveredDevice>? scanningSubscription;
  // мониторинг подключенных устройств
  StreamSubscription<ConnectionStateUpdate>? connectionStateSubscription;

  // Закрытый конструктор
  BleImplementation._internal(this.key);

  // Фабрика для создания или получения экземпляра
  factory BleImplementation(String key) {
    if (_instances.containsKey(key)) {
      return _instances[key]!; // Возвращаем существующий экземпляр
    } else {
      final instance = BleImplementation._internal(key);
      _instances[key] = instance; // Сохраняем новый экземпляр
      return instance;
    }
  }

  // Метод для получения существующего экземпляра по ключу
  static BleImplementation? getInstance(String key) {
    return _instances[key];
  }

  // Метод для удаления экземпляра, если он больше не нужен
  static void removeInstance(String key) {
    _instances.remove(key);
  }

  // Очистка всех экземпляров
  static void clearInstances() {
    _instances.clear();
  }

  // сканирование устройств
  @override
  Future<void> startScanning(WidgetRef ref) async {
    // получаем экземпляр FlutterReactiveBle
    final ble = ref.read(bleProvider);
    // Отменяем предыдущую подписку, если она существует
    await scanningSubscription?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));
    // Очищаем список устройств
    ref.read(scannDevicesProvider.notifier).clearScannDevices();
    // список подключенных устройств
    List<DiscoveredDevice> connectedDevices = ref.read(connectedDevicesProvider);
    for(DiscoveredDevice d in connectedDevices){
      ref.read(scannDevicesProvider.notifier).addScannDevice(d);
    }
    // запуск сканирования устройств
    scanningSubscription = ble.scanForDevices(withServices: serviceUUIDS).listen(
      (device) async {
        scannerHandler(ref, device);
      },
      onError: (error) async {
        log.e('Error during scanning: $error');
        await stopScanning();
      },
      onDone: () async {
        log.i('Scanning complete');
        await stopScanning();
      },
    );
  }

  // остановить сканирование устройств
  @override
  Future<void> stopScanning() async {
    try {
      await scanningSubscription?.cancel();
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (error) {
      log.e(error);
    }
  }

  // мониторинг состояния подключения устройств
  @override
  Future<void> devicesConnectionState(WidgetRef ref) async {
    final ble = ref.read(bleProvider);
    // Отменяем предыдущую подписку, если она существует
    await connectionStateSubscription?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));
    connectionStateSubscription = ble.connectedDeviceStream.listen(
      (device){
        switch (device.connectionState) {
          case DeviceConnectionState.connecting:
            ref.read(deviceStateProvider(device.deviceId).notifier).updateConnectionStatus(
              isConnected: false, 
              loading: true
            );
            break;
          case DeviceConnectionState.connected:
            ref.read(deviceStateProvider(device.deviceId).notifier).updateConnectionStatus(
              isConnected: true, 
              loading: false,
            );
            ref.read(messageProvider.notifier).sendMessage('${device.deviceId} подключено');
            break;
          case DeviceConnectionState.disconnecting:
            break;
          case DeviceConnectionState.disconnected:
            ref.read(deviceStateProvider(device.deviceId).notifier).updateConnectionStatus(
              isConnected: false,
              loading: false,
              subscription: null
            );
            ref.read(connectedDevicesProvider.notifier).deleteConnectedDevice(device.deviceId);
            ref.read(messageProvider.notifier).sendMessage('${device.deviceId} отключено');
            break;
        }
      }
    );
  }
  
  // остановить мониторинг состояния подключения устройств
  @override
  Future<void> closeDevicesConnectionState() async {
    await connectionStateSubscription?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // обработчик отсканированных устройств
  static void scannerHandler(WidgetRef ref, DiscoveredDevice device){
    // список отсканированных устройств
    List<DiscoveredDevice> scannDevices = ref.read(scannDevicesProvider);
    // Проверяем, есть ли устройство в списке отсканированных
    if (!scannDevices.any((d) => d.id == device.id)) {
      // Добавляем новое устройство
      ref.read(scannDevicesProvider.notifier).addScannDevice(device);
    }
  }
  
  

  


}