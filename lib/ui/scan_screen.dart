import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../constants/bms_services.dart';
import '../constants/loger.dart';
import '../constants/styles.dart';
import '../data/ffe0_controller_implements.dart';
import '../data/fff0_controller_implements.dart';
import '../main.dart';
import '../providers/bms_provider.dart';
import '../utils/snackbar.dart';
import 'scan_result_tile.dart';
import 'system_device_tile.dart';

class ScanScreen extends ConsumerStatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final progress;
  const ScanScreen({super.key, required this.progress});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {

  List<ScanResult> scanResults = [];
  List<BluetoothDevice> _systemDevices = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    onScanPressed();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) async {
      scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("ошибка сканирования:", e), success: false);
    });
    
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
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
      _systemDevices.clear();
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      log.d('System Devices Error:: $e');
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10), withServices: requiredServices);
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("ошибка запуска сканирования:", e), success: false);
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
          try {
            await FFE0Implements().connect(r);
            String mac = r.device.remoteId.str;
            Map<String, dynamic> currentWidgets = ref.read(monitoringWidgets);
            currentWidgets[mac] = r;
            ref.read(monitoringWidgets.notifier).state = currentWidgets;
            widget.progress.dismiss();
          } catch (e) {
            Snackbar.show(ABC.b, prettyException("Ошибка при попытке подключения: ", e), success: false);
            widget.progress.dismiss();
          }
        } 
        if (s.toString() == 'fff0') {
          widget.progress.show();
          try {
            await FFF0Implements().connect(r);
            String mac = r.device.remoteId.str;
            Map<String, dynamic> currentWidgets = ref.read(monitoringWidgets);
            currentWidgets[mac] = r;
            ref.read(monitoringWidgets.notifier).state = currentWidgets;
            widget.progress.dismiss();
          } catch (e) {
            Snackbar.show(ABC.b, prettyException("Ошибка при попытке подключения: ", e), success: false);
            widget.progress.dismiss();
          }
        }
        break;
      }
    }
  }

  void onDisconnectPressed(BluetoothDevice device) async {
    String mac = device.remoteId.str;
    _systemDevices.removeWhere((element) => device.remoteId.str == mac);
    Map<String, dynamic> currentResults = ref.read(monitoringWidgets);
    currentResults.remove(mac);
    ref.read(monitoringWidgets.notifier).state = currentResults;
    await device.disconnect().then((value) => onScanPressed());
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

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices.map((d) {
      return SystemDeviceTile(
        device: d,
        onTap: () => onDisconnectPressed(d),
      );
    },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: flavor == 'oem' ? const Color(0xFF42fff9) : const Color(0xFFf68800),
          centerTitle: true,
          title: Text('доступные АКБ', style: dark18, overflow: TextOverflow.visible, textAlign: TextAlign.center,),
          actions: [
            _isScanning ? const Padding(
              padding: EdgeInsets.only(right: 25),
              child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black,),),
            ) : 
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(onPressed: onScanPressed, icon: Icon(MdiIcons.refreshCircle, size: 30,)),
            )
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: flavor == 'oem' ? const BoxDecoration(
            image: DecorationImage(
              opacity: 0.5,
              image: AssetImage('lib/images/oem_bg.png'),
              fit: BoxFit.cover,
            ),
          ) : const BoxDecoration(
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
              _systemDevices.isEmpty && scanResults.isEmpty ? 
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Text('BMS устройства не найдены', style: grey16,),
                  )
                )
              ) :
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  controller: ScrollController(),
                  shrinkWrap: true,
                  children: <Widget>[
                    ..._buildSystemDeviceTiles(context),
                    ..._buildScanResultTiles(context),
                  ],
                ),
              ),
              // buildScanButton(mainContext),
              // const SizedBox(height: 10)
            ],
          ),
        ),
      ),
    );
  }

}