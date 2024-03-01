
import 'package:compass/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../providers/bms_provider.dart';

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

          final data = ref.watch(monitoringWidgets);
          List keys = data.keys.toList();

          return data.isEmpty ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.clipboardSearchOutline, size: 50, color: Colors.orange,),
                const SizedBox(height: 10,),
                Text('не выбрано\nни одного устройства,\nнечего мониторить', style: grey16, textAlign: TextAlign.center,),
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
                return data[mac];
              }
            ),
          );
        }
      );
    
    
    /*
    Scaffold(
      backgroundColor: Colors.black,
      body: Consumer(
        builder: (context, ref, child) {

          final data = ref.watch(monitoringWidgets);
          List keys = data.keys.toList();

          return data.isEmpty ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.clipboardSearchOutline, size: 50, color: Colors.orange,),
                const SizedBox(height: 10,),
                Text('не выбрано\nни одного устройства,\nнечего мониторить', style: grey16, textAlign: TextAlign.center,),
              ],
            ),
          ) : 
          ListView.builder(
            shrinkWrap: true,
            itemCount: data.length,
            itemBuilder: (context, index){
              String mac = keys[index];
              return data[mac];
            }
          );
        }
      ),
    );
    */
  }
}