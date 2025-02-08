import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_repository/ffe0_service_implementation.dart';
import '../models/device_state_model.dart';
import '../static/app_bar_titles.dart';
import '../static/logger.dart';

// Провайдер экземпляра FlutterReactiveBle
final bleProvider = Provider<FlutterReactiveBle>((ref) => FlutterReactiveBle());

// провайдер состояния сканирования
final scanningStateProvider = StateNotifierProvider<ScanningStateNotifier, bool>((ref) {
  return ScanningStateNotifier();
});

class ScanningStateNotifier extends StateNotifier<bool> {
  ScanningStateNotifier() : super(false);

  void startScan() {
    state = true;
  }

  void stopScan() {
    state = false;
  }
}

// провайдер заголовка appBar
final appBarTitleProvider = StateNotifierProvider<AppBarTitleNotifier, String>((ref) {
  return AppBarTitleNotifier();
});

class AppBarTitleNotifier extends StateNotifier<String> {
  AppBarTitleNotifier() : super('доступные АКБ');

  void setTitle(String title) {
    state = title;
  }
}

// провайдер индекса bottomNavigationBar
final bottomBarIndexProvider = StateNotifierProvider<BottomBarIndexNotifier, int>((ref) {
  return BottomBarIndexNotifier(ref);
});

class BottomBarIndexNotifier extends StateNotifier<int> {
  final Ref ref;
  BottomBarIndexNotifier(this.ref) : super(0);

  void setIndex(int index) {
    ref.read(scanningStateProvider.notifier).stopScan();
    ref.read(appBarTitleProvider.notifier).setTitle(appBarTitles[index]);
    state = index;
  }
}

// провайдер сканирования bluetooth устройств
final scannDevicesProvider = StateNotifierProvider<ScannDevicesNotifier, List<DiscoveredDevice>>((ref) {
  return ScannDevicesNotifier(ref);
});

class ScannDevicesNotifier extends StateNotifier<List<DiscoveredDevice>> {
  final Ref ref;
  ScannDevicesNotifier(this.ref) : super([]);

  // добавить сканированное устройство в список
  void addScannDevice(DiscoveredDevice device) {
    // добавляем устройство только если его нет в списке
    if (!state.any((d) => d.id == device.id)) {
      state = [...state, device];
    }
  }

  // удалить устройство из списка сканирования bluetooth устройств
  void delScannDevice(DiscoveredDevice device) {
    final id = device.id;
    state = state.where((device) => device.id != id).toList();
  }

  // очистить список сканирования bluetooth устройств
  void clearScannDevices() {
    state = [];
  }
}

// провайдер подключенных bluetooth устройств
final connectedDevicesProvider = StateNotifierProvider<ConnectedDevicesDevicesNotifier, List<DiscoveredDevice>>((ref) {
  return ConnectedDevicesDevicesNotifier(ref);
});

class ConnectedDevicesDevicesNotifier extends StateNotifier<List<DiscoveredDevice>> {
  final Ref ref;
  ConnectedDevicesDevicesNotifier(this.ref) : super([]);

  // добавить подключенное устройство в список
  void addConnectedDevice(DiscoveredDevice device) {
    // добавляем устройство только если его нет в списке
    if (!state.any((d) => d.id == device.id)) {
      state = [...state, device];
    }
  }

  // удалить подключенное устройство из списка
  void deleteConnectedDevice(String deviceID) {
    state = state.where((device) => device.id != deviceID).toList();
  }
}


// провайдер состояния подключения подключенных bluetooth устройств
final deviceStateProvider = StateNotifierProvider.family<DeviceStateNotifier, DeviceStateModel, String>(
  (ref, deviceId) => DeviceStateNotifier(deviceId),
);

class DeviceStateNotifier extends StateNotifier<DeviceStateModel> {
  DeviceStateNotifier(String deviceId) : super(DeviceStateModel(deviceId: deviceId));

  void updateConnectionStatus({DiscoveredDevice? device, bool? isConnected, bool? loading, StreamSubscription<ConnectionStateUpdate>? subscription}) {
    state = state.copyWith(
      device: device,
      isConnected: isConnected, 
      loading: loading,
      subscription: subscription
    );
  }

}


// провайдер сообщений
final messageProvider = StateNotifierProvider<MessageNotifier, String>((ref) {
  return MessageNotifier();
});

class MessageNotifier extends StateNotifier<String> {
  MessageNotifier() : super('');

  void sendMessage(String message) {
    state = message;
    // Через 3 секунды сбрасываем сообщение
    Future.delayed(const Duration(seconds: 3), () {
      state = '';
    });
  }
}


// трансляция показаний BMS устройства
final bmsDataStreamProvider = StreamProvider.family.autoDispose<Map<String, dynamic>, String>(
  (ref, deviceID) async* {
    dynamic implementsClass;
    final ble = ref.read(bleProvider);
    final services = await ble.getDiscoveredServices(deviceID);

    for(var service in services){
      if(service.id.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb'){
        log.i('запуск stream для ffe0');
        implementsClass = FFE0ServiceImplementation(ble: ble, deviceID: deviceID);
      }
      if(service.id.toString() == '0000fff0-0000-1000-8000-00805f9b34fb'){
        null;
      }
    }
    ref.onDispose(() {
      implementsClass.disposeStreamDependencies();
    });
    yield* await implementsClass.ffe0Stream();
  }
);

