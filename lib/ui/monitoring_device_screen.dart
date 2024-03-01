
import 'package:compass/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bms_provider.dart';

class MonitoringDeviceScreen extends ConsumerStatefulWidget {
  final ScanResult r;
  const MonitoringDeviceScreen({super.key, required this.r});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MonitoringDeviceScreenState();
}

class _MonitoringDeviceScreenState extends ConsumerState<MonitoringDeviceScreen> {

  late String mac;
  late String name;

  @override
  void initState() {
    super.initState();
    initDeviceInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initDeviceInfo(){
    setState(() {
      mac = widget.r.device.remoteId.str;
      name = widget.r.device.platformName.isEmpty ? 'NoName' : widget.r.device.platformName.toString();
    });
  }

  Widget loading(){
    return Container(
      padding: const EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width,
      height: 150,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black, strokeWidth: 3,),
            const SizedBox(height: 15,),
            Text('обновление\nпоказаний', style: dark12, textAlign: TextAlign.center,)
          ],
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child){
        final batteryData = ref.watch(bmsDataStreamProvider(widget.r));
        return batteryData.when(
          error: (error, stack) => Text('Error: $error'), 
          loading: () => loading(),
          // data: (data) => Center(child: Text(data.toString(), style: white14,)),
          data: (data) {
            return Container(
              padding: const EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: Colors.white,
              ),
              child: ExpansionTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$name\nMAC: $mac'),
                    const SizedBox(height: 8,),
                    Text(data['voltage']),
                    Text(data['current']),
                  ],
                ),
                children: const[
                  Text('data 1'),
                  Text('data 2'),
                  Text('data 3'),
                  Text('data 4'),
                ],
              ),
            );
          }, 
        );
      }
    );
  }
}