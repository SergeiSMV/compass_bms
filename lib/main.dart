import 'dart:async';

import 'package:compass/ui/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/bluetooth_off_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const ProviderScope(child: App()));
  });
}


class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;


  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    Widget screen = _adapterState == BluetoothAdapterState.on
        ? const MainScreen()
        : BluetoothOffScreen(adapterState: _adapterState);


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.lightBlue,
      home: screen,
      // navigatorObservers: [BluetoothAdapterStateObserver()],
    );
  }
}

//
// Этот наблюдатель прослушивает Bluetooth Off и закрывает DeviceScreen.
//
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/DeviceScreen') {
      // Начните прослушивать изменения состояния Bluetooth при нажатии нового маршрута.
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((state) {
        if (state != BluetoothAdapterState.on) {
          // Вспомнить текущий маршрут, если Bluetooth выключен
          navigator?.pop();
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Отменить подписку при открытии маршрута
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}