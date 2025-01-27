
import 'package:compass_bms_app/static/keys.dart';
import 'package:compass_bms_app/ui/global_widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ble_repository/ble_implementation.dart';


class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {

  final BleImplementation bleImplementation = BleImplementation(bleImplementationKey);


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bleImplementation.devicesConnectionState(ref);
    });
  }

  @override
  void dispose() {
    bleImplementation.closeDevicesConnectionState();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.lightBlue,
      home: MainScaffold(),
    );
  }
}