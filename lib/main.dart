
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:permission_handler/permission_handler.dart';

// ignore: unused_import
import '_old/old_main_app.dart';
import 'ui/global_widgets/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();


  await Hive.initFlutter();
  await Hive.openBox('hiveStorage');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(
      const ProviderScope(
        child: 
          // App() // old_version
          MainApp() // new version
      )
    );
  });
}

Future<void> requestPermissions() async {
  if (await Permission.bluetoothScan.isDenied) {
    await Permission.bluetoothScan.request();
  }
  if (await Permission.bluetoothConnect.isDenied) {
    await Permission.bluetoothConnect.request();
  }
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
}