



import 'dart:async';

import 'package:compass/utils/extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/devices.dart';
import '../constants/styles.dart';
import '../utils/snackbar.dart';
import 'device_screen.dart';
import 'scan_result_tile.dart';
import 'system_device_tile.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {

  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results){
        scanResults.contains(r) ? null :
        r.device.platformName.isNotEmpty && devices.contains(r.device.platformName) ? scanResults.add(r) : null;
      }
      // _scanResults = results;
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
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
    });
    MaterialPageRoute route = MaterialPageRoute(builder: (context) => DeviceScreen(device: device), settings: const RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context).push(route);
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: ElevatedButton(
          style: ButtonStyle(
            elevation: MaterialStateProperty.all<double>(2),
            backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFb4b4b5)),
            minimumSize: MaterialStateProperty.all<Size>(Size(MediaQuery.of(context).size.width, 50)),
          ),
          onPressed: onStopPressed, 
          child: Text('стоп', style: white16)
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

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices.map((d) => SystemDeviceTile(
        device: d,
        onOpen: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DeviceScreen(device: d),
            settings: const RouteSettings(name: '/DeviceScreen'),
          ),
        ),
        onConnect: () => onConnectPressed(d),
      ),
    ).toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return scanResults.map((r) {
      return ScanResultTile(
        result: r,
        onTap: () => onConnectPressed(r.device),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFFf68800),
          centerTitle: true,
          title: Text('доступные устройства', style: dark18,),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            image: DecorationImage(
              opacity: 0.5,
              image: scanResults.isEmpty ? const AssetImage('lib/images/cable.png') : const AssetImage('lib/images/atom.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10,),
                ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    ..._buildSystemDeviceTiles(context),
                    ..._buildScanResultTiles(context),
                  ],
                ),
                scanResults.isEmpty ? Expanded(
                  child: Center(child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Text('нажмите поиск', style: white16,),
                  ))) 
                  : const Expanded(child: SizedBox(height: 5,)),
                buildScanButton(context),
                const SizedBox(height: 10)
              ],
            ),
          ),
        ),
        
        // floatingActionButton: buildScanButton(context),
      ),
    );
  }
}