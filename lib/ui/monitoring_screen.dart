
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../constants/styles.dart';
import '../main.dart';
import '../providers/bms_provider.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: flavor == 'oem' ? const Color(0xFF42fff9) : const Color(0xFFf68800),
        centerTitle: true,
        title: Text('мониторинг устройств', style: dark18,),
      ),
      body: Consumer(
        builder: (context, ref, child) {
    
          final data = ref.watch(monitoringWidgets);
          List keys = data.keys.toList();
    
          return data.isEmpty ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.clipboardSearchOutline, size: 50, color: flavor == 'oem' ? const Color(0xFF42fff9) : Colors.orange,),
                const SizedBox(height: 10,),
                Text('не выбрано\nни одного устройства', style: white16, textAlign: TextAlign.center,),
              ],
            ),
          ) : 
          Padding(
            padding: const EdgeInsets.only(left: 5, right: 5, top: 8, bottom: 8),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (context, index){
                String mac = keys[index];
                return Padding(
                  padding: const EdgeInsets.only(left: 3, right: 3, top: 4, bottom: 4),
                  child: MonitoringDeviceScreen(r: data[mac], key: ValueKey(data.length),),
                );
              }
            ),
          );
        }
      ),
    );
  }

}