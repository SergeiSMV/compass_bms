import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../constants/stark_devices.dart';
import '../constants/styles.dart';
import '../data/hive_implements.dart';
import '../main.dart';

class SystemDeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;

  const SystemDeviceTile({
    required this.device,
    required this.onTap,
    super.key,
  });

  @override
  State<SystemDeviceTile> createState() => _SystemDeviceTileState();
}

class _SystemDeviceTileState extends State<SystemDeviceTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  String techName = '';

  @override
  void initState() {
    super.initState();
    getName();
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
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
    DeviceIdentifier mac = widget.device.remoteId;
    techName = await HiveImplements().getDeviceName(mac.toString());
    if (mounted) {
      setState(() {});
    }
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.device.platformName.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('${widget.device.platformName}${techName.isEmpty ? '' : '\n($techName)'}', overflow: TextOverflow.clip, style: white16,),
          // Text('MAC: ${widget.device.remoteId.str}', style: white12,)
        ],
      );
    } else {
      return Text(
        widget.device.remoteId.str, 
        style: white16,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              starkDevices.contains(widget.device.remoteId) && flavor == 'stark' ? Image.asset('lib/images/stark_label_white.png', scale: 10.0) : const SizedBox.shrink(),
              starkDevices.contains(widget.device.remoteId) && flavor == 'stark' ? const SizedBox(height: 10,) : const SizedBox.shrink(),
              _buildTitle(context),
            ],
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: widget.onTap,
            child: Text('отключить', style: white14,),
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
