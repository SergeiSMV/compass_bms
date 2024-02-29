import 'dart:async';

import 'package:compass/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bms_provider.dart';

class MonitoringDeviceScreen extends ConsumerStatefulWidget {
  final ScanResult r;
  final StreamSubscription<dynamic>? charSubscription;
  const MonitoringDeviceScreen({super.key, required this.r, required this.charSubscription});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MonitoringDeviceScreenState();
}

class _MonitoringDeviceScreenState extends ConsumerState<MonitoringDeviceScreen> {

  late String mac = widget.r.device.remoteId.str;

  @override
  void initState() {
    super.initState();
    mac = widget.r.device.remoteId.str;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child){
        final batteryData = ref.watch(monitoringProvider.select((value) => value[mac]['provider']));
        return Center(child: Text(batteryData.toString(), style: white14,),);
      }
    );
  }
}