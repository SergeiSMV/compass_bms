import 'package:compass_bms_app/static/keys.dart';
import 'package:compass_bms_app/ui/static_ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

import '../../data/ble_repository/ble_implementation.dart';
import '../../riverpod/riverpod.dart';
import 'scan_device_title.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {

  final BleImplementation bleImplementation = BleImplementation(bleImplementationKey);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    bleImplementation.stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<DiscoveredDevice> devices = ref.watch(scannDevicesProvider);
    return devices.isEmpty ?
    RippleAnimation(
      color: primaryAppColor,
      delay: const Duration(milliseconds: 300),
      repeat: true,
      minRadius: 40,
      maxRadius: 60,
      ripplesCount: 6,
      duration: const Duration(milliseconds: 6 * 300),
      child: Align(
        alignment: Alignment.center,
        child: InkWell(
          onTap: (){
            bleImplementation.startScanning(ref);
            ref.read(scanningStateProvider.notifier).startScan();
            ref.read(messageProvider.notifier).sendMessage('сканирование');
          },
          child: Container(
            decoration: BoxDecoration(
              color: primaryAppColor,
              shape: BoxShape.circle,
            ),
            height: 70,
            width: 70,
            child: Icon(MdiIcons.accessPoint, color: Colors.black, size: 35,)
          ),
        ),
      ),
    )
    :
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: devices.length,
        itemBuilder: (context, index){
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: ScanDeviceTitle(device: devices[index], key: UniqueKey(),),
          );
        }
      ),
    );
  }
}
