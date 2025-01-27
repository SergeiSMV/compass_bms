import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_state_model.dart';
import '../static/app_bar_titles.dart';

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


// провайдер состояния подключения
final deviceStateProvider = StateNotifierProvider.family.autoDispose<DeviceStateNotifier, DeviceStateModel, String>(
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

/*
// обновленный список устройств
final devicesStateProvider = StateNotifierProvider<DevicesStateNotifier, List<DeviceStateModel>>((ref) {
  return DevicesStateNotifier();
});

class DevicesStateNotifier extends StateNotifier<List<DeviceStateModel>> {
  DevicesStateNotifier() : super([]);

  void addDevice(DiscoveredDevice device) {
    if (!state.any((d) => d.deviceId == device.id)) {
      state = [
        ...state,
        DeviceStateModel(
          deviceId: device.id,
          device: device,
        ),
      ];
    }
  }

  void updateDevice(String deviceId, {bool? isConnected, bool? loading, StreamSubscription<ConnectionStateUpdate>? subscription}) {
    state = state.map((device) {
      if (device.deviceId == deviceId) {
        return device.copyWith(
          isConnected: isConnected ?? device.isConnected,
          loading: loading ?? device.loading,
          subscription: subscription ?? device.subscription,
        );
      }
      return device;
    }).toList();
  }

  void removeDevice(String deviceId) {
    state = state.where((device) => device.deviceId != deviceId).toList();
  }

  void clearDevices() {
    state = [];
  }
}
*/




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

