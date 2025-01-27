import 'package:compass_bms_app/riverpod/riverpod.dart';
import 'package:compass_bms_app/static/keys.dart';
import 'package:compass_bms_app/ui/static_ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../data/ble_repository/ble_implementation.dart';

class ScanButton extends ConsumerWidget {
  ScanButton({super.key});

  final BleImplementation bleImplementation = BleImplementation(bleImplementationKey);

  Future<void> _handleScanTap(WidgetRef ref, bool isScanning) async {
    if(isScanning){
      await bleImplementation.stopScanning();
      ref.read(scanningStateProvider.notifier).stopScan();
      ref.read(messageProvider.notifier).sendMessage('сканирование завершено');
    } else {
      bleImplementation.startScanning(ref);
      ref.read(scanningStateProvider.notifier).startScan();
      ref.read(messageProvider.notifier).sendMessage('сканирование');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    
    bool isScanning = ref.watch(scanningStateProvider);
    int currentScreenIndex = ref.watch(bottomBarIndexProvider);

    return InkWell(
      onTap: () => _handleScanTap(ref, isScanning),
      child: Padding(
        padding: const EdgeInsets.only(right: 19),
        child: Container(
          height: 30,
          width: 53,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            color: Colors.black.withOpacity(0.8),
          ),
          child: currentScreenIndex == 0 ? 
            isScanning ?
              SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryAppColor,
                ),
              )
              :
              Icon(
                MdiIcons.accessPoint,
                size: 25,
                color: primaryAppColor,
              )
          :
          const SizedBox.shrink()
        ),
      ),
    );
  }
}
