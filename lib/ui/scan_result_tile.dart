import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/stark_devices.dart';
import '../constants/styles.dart';
import '../data/hive_implements.dart';
import '../main.dart';


class ScanResultTile extends StatefulWidget {
  const ScanResultTile({super.key, required this.result, this.onTap});

  final ScanResult result;
  final VoidCallback? onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  String techName = '';

  @override
  void initState() {
    super.initState();
    getName();
    _connectionStateSubscription = widget.result.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  Future getName() async {
    DeviceIdentifier mac = widget.result.device.remoteId;
    techName = await HiveImplements().getDeviceName(mac.toString());
    if (mounted) {
      setState(() {});
    }
  }

  // NOT USED getNiceHexArray, getNiceManufacturerData, getNiceServiceData, getNiceServiceUuids
  /*
  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]';
  }

  String getNiceManufacturerData(List<List<int>> data) {
    return data.map((val) => getNiceHexArray(val)).join(', ').toUpperCase();
  }

  String getNiceServiceData(Map<Guid, List<int>> data) {
    return data.entries.map((v) => '${v.key}: ${getNiceHexArray(v.value)}').join(', ').toUpperCase();
  }

  String getNiceServiceUuids(List<Guid> serviceUuids) {
    return serviceUuids.join(', ').toUpperCase();
  }
  */

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.result.device.platformName.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${widget.result.device.platformName}${techName.isEmpty ? '' : '\n($techName)'}', overflow: TextOverflow.clip, style: white16),
          // Text('MAC: ${widget.result.device.remoteId.str}', style: white12,)
        ],
      );
    } else {
      return Text(
        widget.result.device.remoteId.str, 
        style: widget.result.advertisementData.connectable ? white16 : grey14,
      );
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected ? Colors.red : flavor == 'oem' ? const Color(0xFF42fff9) : Colors.orange,
        foregroundColor: Colors.white,
      ),
      onPressed: (widget.result.advertisementData.connectable) ? widget.onTap : null,
      child: isConnected ? Text('отключить', style: white14,) :
      Text(widget.result.advertisementData.connectable ? 'соединение' : 'закрыт', 
        style: widget.result.advertisementData.connectable ? dark14 : grey14,
      ),
    );
  }

  
  // ignore: unused_element
  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: white12),
        const SizedBox(width: 5),
        Expanded(child: Text(value, style: white12, softWrap: true,),),
      ],
    );
  }
  

  @override
  Widget build(BuildContext context) {
    // var adv = widget.result.advertisementData;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(5)
            ),
            
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  starkDevices.contains(widget.result.device.remoteId) && flavor == 'stark' ? Image.asset('lib/images/stark_label_white.png', scale: 10.0) : const SizedBox.shrink(),
                  starkDevices.contains(widget.result.device.remoteId) && flavor == 'stark' ? const SizedBox(height: 10,) : const SizedBox.shrink(),
                  _buildTitle(context),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildConnectButton(context),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: Divider(color: Colors.white,),
        )
      ],
    );
  }

}
