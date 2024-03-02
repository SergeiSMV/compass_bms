
import 'package:compass/constants/styles.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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

  Widget remainIndicator(int remain){
    Color color;
    if (remain >= 90) {
      color = Colors.lightGreen;
    } else if (remain >= 80) {
      color = Colors.lightGreen.shade400;
    } else if (remain >= 70) {
      color = Colors.lightGreen.shade200;
    } else if (remain >= 60) {
      color = Colors.orange.shade200;
    } else if (remain >= 40) {
      color = Colors.orange.shade300;
    } else if (remain >= 40) {
      color = Colors.orange;
    } else if (remain >= 20) {
      color = Colors.orange.shade800;
    } else if (remain >= 10) {
      color = Colors.orange.shade900;
    } else {
      color = Colors.red;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: Row(
        children: [
          
          
          Flexible(
            child: LinearProgressIndicator(
              value: remain / 100.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          Text('$remain%', style: grey14,),
        ],
      ),
    );
  }

  Widget subtitle(double? value, String unit){

    TextStyle style = value != null && unit == 'A' ? (value < 0 ? red18 : (value > 0 ? green18 : dark18)) : dark18;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            spreadRadius: 0.0,
            blurRadius: 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text('${value ?? '0'} $unit', style: style,),
      ),
    );
  }

  Widget cellsInfo(Map<String, dynamic> data){

    int lengthCells = List.generate(32, (index) {
      return 'cell ${index + 1}';
    }).where((cellKey) => data.containsKey(cellKey)).length;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Количество колонок
          childAspectRatio: 3, // Отношение ширины к высоте каждого элемента
          crossAxisSpacing: 5, // Пространство между колонками
          mainAxisSpacing: 5, // Пространство между рядами
        ),
        itemCount: lengthCells,
        itemBuilder: (context, index) {
          String cellKey = 'cell ${index + 1}';
          return data.containsKey(cellKey) ? 
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    spreadRadius: 0.0,
                    blurRadius: 0.5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.battery_std, color: Colors.grey.shade800, size: 30,),
                      Text('${index + 1}', style: white10),
                    ],
                  ),
                  const SizedBox(width: 5),
                  Expanded(child: Text('${data[cellKey]}', style: dark16)),
                ],
              ),
            )
          : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget tempInfo(Map<String, dynamic> data){

    int lengthTemp = List.generate(2, (index) {
      return 'temp ${index + 1}';
    }).where((cellKey) => data.containsKey(cellKey)).length;

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Количество колонок
          childAspectRatio: 3, // Отношение ширины к высоте каждого элемента
          crossAxisSpacing: 5, // Пространство между колонками
          mainAxisSpacing: 5, // Пространство между рядами
        ),
        itemCount: lengthTemp,
        itemBuilder: (context, index) {
          String cellKey = 'temp ${index + 1}';
          return data.containsKey(cellKey) ? 
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    spreadRadius: 0.0,
                    blurRadius: 0.5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(MdiIcons.thermometer, color: Colors.grey.shade800, size: 25,),
                      Positioned(
                        top: 10,
                        right: -1,
                        child: Text('${index + 1}', style: dark12,)
                      )
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${data[cellKey]}', style: dark16)),
                ],
              ),
            )
          : const SizedBox.shrink();
        },
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
          data: (data) {
            return Container(
              padding: const EdgeInsets.all(5),
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: Colors.white,
              ),
              child: ExpansionTileCard(
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: dark16,),
                          Text('MAC: $mac', style: dark12,),
                        ],
                      ),
                    ),
                    /*
                    Text('${data['power'] ?? ''}W', style: grey14,),
                    Icon(
                      data['current'] == null || data['current'] == 0 ? MdiIcons.batteryOutline : (data['current'] > 0 ? MdiIcons.powerPlugBattery : MdiIcons.batteryCharging100), 
                      color: data['current'] == null || data['current'] == 0 ? Colors.grey : (data['current'] > 0 ? Colors.green : Colors.red),
                      size: 20,
                    )
                    */
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(child: subtitle(data['voltage'], 'V')),
                          const SizedBox(width: 5),
                          Flexible(child: subtitle(data['current'], 'A'))
                        ],
                      ),
                      remainIndicator(data['remain'] ?? 0),
                    ],
                  ),
                ),
                children: [
                  const Divider(
                    indent: 8,
                    endIndent: 8,
                    thickness: 1.0,
                    height: 1.0,
                  ),
                  const SizedBox(height: 15,),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                        color: Colors.grey.shade300,
                      ),
                      child: Center(child: Text('напряжение ячеек', style: dark16,))
                    ),
                  ),
                  const SizedBox(height: 5,),
                  cellsInfo(data),
                  const SizedBox(height: 15),
                  const Divider(
                    indent: 8,
                    endIndent: 8,
                    thickness: 1.0,
                    height: 1.0,
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                        color: Colors.grey.shade300,
                      ),
                      child: Center(child: Text('температура', style: dark16,))
                    ),
                  ),
                  const SizedBox(height: 5,),
                  tempInfo(data),
                  const SizedBox(height: 15),
                ],
              )
            );
          }, 
        );
      }
    );
  }
}