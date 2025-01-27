import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../old_constants/old_stark_devices.dart';
import '../old_constants/old_styles.dart';
import '../old_data/old_hive_implements.dart';
import '../old_main_app.dart';

class ConnectedDeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;

  const ConnectedDeviceTile({
    required this.device,
    required this.onTap,
    super.key,
  });

  @override
  State<ConnectedDeviceTile> createState() => _ConnectedDeviceTileState();
}

class _ConnectedDeviceTileState extends State<ConnectedDeviceTile> {

  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  String techName = '';

  @override
  void initState() {
    super.initState();
    getName();
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      connectionState = state;
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

  // NOT USED isConnected
  /*
  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
  */

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
