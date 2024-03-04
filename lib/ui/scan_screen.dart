import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/bms_services.dart';
import '../constants/styles.dart';
import '../data/ffe0_controller_implements.dart';
import '../data/fff0_controller_implements.dart';
import '../providers/bms_provider.dart';
import '../utils/snackbar.dart';
import 'monitoring_device_screen.dart';
import 'scan_result_tile.dart';

class ScanScreen extends ConsumerStatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final progress;
  const ScanScreen({super.key, required this.progress});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {

  List<ScanResult> scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) async {
      scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("ошибка сканирования:", e), success: false);
    });
    
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {});
      }
    });

  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10), withServices: requiredServices);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("ошибка запуска сканирования:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("ошибка остановки сканирования:", e), success: false);
    }
  }

  void onConnectPressed(ScanResult r) async {
    var adv = r.advertisementData;
    List<Guid> services = adv.serviceUuids;
    for (var s in services){
      if (requiredServices.contains(s)){
        if (s.toString() == 'ffe0'){
          widget.progress.show();
          await FFE0Implements().connect(r);
          String mac = r.device.remoteId.str;
          Map<String, Widget> currentWidgets = ref.read(monitoringWidgets);
          currentWidgets[mac] = MonitoringDeviceScreen(r: r);
          ref.read(monitoringWidgets.notifier).state = currentWidgets;
          widget.progress.dismiss();
        } 
        if (s.toString() == 'fff0') {
          widget.progress.show();
          await FFF0Implements().connect(r);
          String mac = r.device.remoteId.str;
          Map<String, Widget> currentWidgets = ref.read(monitoringWidgets);
          currentWidgets[mac] = MonitoringDeviceScreen(r: r);
          ref.read(monitoringWidgets.notifier).state = currentWidgets;
          widget.progress.dismiss();
        }
        break;
      }
    }
  }

  void onDisconnectPressed(BluetoothDevice device) async {
    String mac = device.remoteId.str;
    Map<String, Widget> currentWidgets = ref.read(monitoringWidgets);
    currentWidgets.remove(mac);
    ref.read(monitoringWidgets.notifier).state = currentWidgets;
    await device.disconnect();
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: ElevatedButton(
          style: ButtonStyle(
            elevation: MaterialStateProperty.all<double>(2),
            backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFb4b4b5)),
            minimumSize: MaterialStateProperty.all<Size>(Size(MediaQuery.of(context).size.width, 45)),
          ),
          onPressed: onStopPressed, 
          child: Text('остановить', style: white16)
        )
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: ElevatedButton(
          style: ButtonStyle(
            elevation: MaterialStateProperty.all<double>(2),
            backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFf68800)),
            minimumSize: MaterialStateProperty.all<Size>(Size(MediaQuery.of(context).size.width, 50)),
          ),
          onPressed: onScanPressed, 
          child: Text('поиск', style: dark16)
        )
      );
    }
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return scanResults.map((r) {
      return ScanResultTile(
        result: r,
        onTap: () => r.device.isConnected ? onDisconnectPressed(r.device) : onConnectPressed(r),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            opacity: 0.7,
            image: AssetImage('lib/images/atom.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10,),
            scanResults.isEmpty ? const SizedBox.shrink() : Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                controller: ScrollController(),
                shrinkWrap: true,
                children: <Widget>[
                  ..._buildScanResultTiles(context),
                ],
              ),
            ),
            scanResults.isEmpty ? Expanded(
              child: Center(child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Text('нажмите поиск', style: white16,),
              ))) 
              : const SizedBox(height: 5,),
            buildScanButton(context),
            const SizedBox(height: 10)
          ],
        ),
      ),
      /*
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              opacity: 0.7,
              image: AssetImage('lib/images/atom.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10,),
              scanResults.isEmpty ? const SizedBox.shrink() : Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  controller: ScrollController(),
                  shrinkWrap: true,
                  children: <Widget>[
                    ..._buildScanResultTiles(context),
                  ],
                ),
              ),
              scanResults.isEmpty ? Expanded(
                child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Text('нажмите поиск', style: white16,),
                ))) 
                : const SizedBox(height: 5,),
              buildScanButton(context),
              const SizedBox(height: 10)
            ],
          ),
        ),
        // bottomNavigationBar: bottomNavBar(),
      ),
      */
    );
  }
}