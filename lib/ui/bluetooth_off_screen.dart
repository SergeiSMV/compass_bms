import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/styles.dart';
import '../main.dart';
import '../utils/snackbar.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.adapterState}) : super(key: key);

  final BluetoothAdapterState? adapterState;

  Widget buildBluetoothOffIcon(BuildContext context) {
    return const Icon(
      Icons.bluetooth_disabled,
      size: 200.0,
      color: Color(0xFFb4b4b5),
    );
  }

  Widget buildTitle(BuildContext context) {
    String? state = adapterState?.toString().split(".").last;
    return Text(
      'служба Bluetooth ${state == null ? 'not available' : state == 'off' ? 'отключена' : 'включена'}',
      style: white14,
    );
  }

  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 70, left: 70),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => flavor == 'oem' ? const Color(0xFF42fff9) : const Color(0xFFf68800)),
        ),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            }
          } catch (e) {
            Snackbar.show(ABC.a, prettyException("ошибка при попытке включить службы:", e), success: false);
          }
        }, 
        child: Padding(
          padding: const EdgeInsets.only(left: 45, right: 45, bottom: 3),
          child: Text('включить', style: dark16),
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Цвет иконок статус бара на светлом фоне
        statusBarIconBrightness: Brightness.light,
        // Цвет иконок статус бара на темном фоне
        // statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent
      )
    );

    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyA,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildBluetoothOffIcon(context),
              const SizedBox(height: 20,),
              buildTitle(context),
              if (Platform.isAndroid) buildTurnOnButton(context),
            ],
          ),
        ),
      ),
    );
  }
}