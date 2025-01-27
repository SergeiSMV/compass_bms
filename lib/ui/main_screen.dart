
import 'package:compass_bms_app/data/ble_repository/ble_implementation.dart';
import 'package:compass_bms_app/riverpod/riverpod.dart';
import 'package:compass_bms_app/static/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'global_widgets/top_message.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainScreen> {

  late BleImplementation bleImplementation;
  late FlutterReactiveBle flutterReactiveBle;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    bleImplementation = BleImplementation(bleImplementationKey);
    final bleProviderValue = ref.read(bleProvider);
    flutterReactiveBle = bleProviderValue;
  }

  @override
  Widget build(BuildContext context) {
    ref.read(bleProvider);
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: (){
                  bleImplementation.startScanning(ref);
                  ref.read(scanningStateProvider.notifier).startScan();
                  TopMessage.show(context, 'сканирование', MdiIcons.bluetoothAudio);
                }, 
                child: const Text('Start scann')
              ),
              TextButton(
                onPressed: () async {
                  await bleImplementation.stopScanning().then((_){
                    ref.read(scanningStateProvider.notifier).stopScan();
                    if (!context.mounted) return;
                    TopMessage.show(context, 'сканирование завершено', MdiIcons.bluetooth);
                  });
                  
                }, 
                child: const Text('Stop csann')
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Consumer(
                  builder: (context, ref, child){
                    bool isScan = ref.watch(scanningStateProvider);
                    return isScan ?
                      const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black,),
                      )
                      :
                      const SizedBox.shrink();
                  }
                ),
              )
            ],
          )
        ),
      )
    );
  }
}