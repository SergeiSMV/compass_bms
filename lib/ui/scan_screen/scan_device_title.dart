import 'dart:async';

import 'package:compass_bms_app/data/ble_repository/ble_connect_implementation.dart';
import 'package:compass_bms_app/static/keys.dart';
import 'package:compass_bms_app/ui/static_ui/colors.dart';
import 'package:compass_bms_app/ui/static_ui/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../data/ble_repository/ble_implementation.dart';
import '../../models/device_state_model.dart';
import '../../riverpod/riverpod.dart';
import '../../static/logger.dart';
import '../../static/stark_devices.dart';


class ScanDeviceTitle extends ConsumerStatefulWidget {
  final DiscoveredDevice device;
  const ScanDeviceTitle({super.key, required this.device});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ScanDeviceTitleState();
}

class _ScanDeviceTitleState extends ConsumerState<ScanDeviceTitle> {

  DiscoveredDevice get _device => widget.device;

  final BleImplementation bleImplementation = BleImplementation(bleImplementationKey);
  late final BleConnectImplementation bleConnectImplementation;

  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bleConnectImplementation = BleConnectImplementation(device: _device);
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                starkDevices.contains(_device.id) ? 
                  Image.asset('lib/images/stark_label_white.png', scale: 13.0) 
                  : const SizedBox.shrink(),
                Text(
                  _device.name.isEmpty ? 
                  _device.id : _device.name, 
                  style: white14,
                ),
                _device.name.isEmpty ? const SizedBox.shrink() :
                Text(
                  'mac: ${_device.id}', 
                  style: white12,
                ),
              ],
            ),
            _device.connectable == Connectable.available ?
            Consumer(
              builder: (context, ref, child) {

                DeviceStateModel deviceState = ref.watch(deviceStateProvider(_device.id));
                StreamSubscription<ConnectionStateUpdate>? subscription = deviceState.subscription;
                bool isConnected = deviceState.isConnected;
                bool loading = deviceState.loading;

                return loading ?
                Padding(
                  padding: const EdgeInsets.only(right: 17),
                  child: Icon(
                    MdiIcons.bluetoothConnect, color: primaryAppColor, size: 25,
                  ),
                )
                :
                Switch(
                  value: isConnected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    return Colors.transparent; // Без обводки
                  }),
                  activeColor: const Color(0xFF04FF11),
                  activeTrackColor: Colors.black,
                  inactiveTrackColor: Colors.white,
                  inactiveThumbColor: Colors.black87,
                  onChanged: (value) async {
                    if(value){
                      bleConnectImplementation.deviceConnect(ref);
                    } else {
                      await subscription?.cancel();
                      await Future.delayed(const Duration(milliseconds: 300));
                    }
                  },
                );
              }
            )
            :
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(MdiIcons.shieldLock, color: primaryAppColor, size: 25,),
            )
          ],
        ),
      ),
    );
  }
}