
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../riverpod/riverpod.dart';
import '../static_ui/text_styles.dart';
import 'monitoring_device_screen.dart';


class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
  
        final devices = ref.watch(connectedDevicesProvider);
        // List keys = data.keys.toList();
  
        return devices.isEmpty ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(MdiIcons.clipboardSearchOutline, size: 50, color: Colors.orange,),
              const SizedBox(height: 10,),
              Text('не выбрано\nни одного устройства', style: white16, textAlign: TextAlign.center,),
            ],
          ),
        ) : 
        Padding(
          padding: const EdgeInsets.only(left: 5, right: 5, top: 8, bottom: 8),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index){
              return Padding(
                padding: const EdgeInsets.only(left: 3, right: 3, top: 4, bottom: 4),
                child: MonitoringDeviceScreen(d: devices[index], key: ValueKey(devices.length),),
              );
            }
          ),
        );
      }
    );
  }

}