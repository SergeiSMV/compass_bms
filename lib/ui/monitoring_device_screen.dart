import 'package:compass/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../constants/stark_devices.dart';
import '../data/hive_implements.dart';
import '../main.dart';
import '../providers/bms_provider.dart';
import 'rename_device.dart';

class MonitoringDeviceScreen extends ConsumerStatefulWidget {
  final ScanResult r;
  const MonitoringDeviceScreen({super.key, required this.r});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MonitoringDeviceScreenState();
}

class _MonitoringDeviceScreenState extends ConsumerState<MonitoringDeviceScreen> with SingleTickerProviderStateMixin {

  TextEditingController nameController = TextEditingController();

  late DeviceIdentifier mac;
  late String deviceName;
  String name = '';

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_controller);
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    initDeviceInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.clear();
    nameController.dispose();
    super.dispose();
  }

  void handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void initDeviceInfo() async {
    mac = widget.r.device.remoteId;
    deviceName = widget.r.device.platformName.isEmpty ? 'NoName' : widget.r.device.platformName.toString();
    nameController.text = await HiveImplements().getDeviceName(mac.toString());
    if (mounted) {
      setState(() {});
    }
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
    List<Color> colorsGradient = [
      Colors.red,
      Colors.orange.shade900,
      Colors.orange.shade800,
      Colors.orange,
      Colors.orange.shade300,
      Colors.yellow.shade600,
      Colors.yellow,
      Colors.lightGreen.shade200,
      Colors.lightGreen.shade300,
      Colors.lightGreen.shade400,
      Colors.lightGreen,
      Colors.lightGreen.shade600,
      Colors.lightGreen.shade700
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 0),
      child: Row(
        children: [
          Flexible(
            child: Container(
              height: 15, // Высота индикатора
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), // Закругление краев
                color: Colors.grey[300], // Фон индикатора
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade600,
                    spreadRadius: 0.0,
                    blurRadius: 0.5,
                    offset: const Offset(0, 2), // changes position of shadow
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: remain / 100.0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colorsGradient, // Градиент от красного к зеленому
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    )
                  )
                ],
              ),
            )
          ),
          const SizedBox(width: 10),
          Text('$remain%', style: grey16,),
        ],
      ),
    );
  }

  Widget subtitle(double? value, String unit){

    TextStyle style = value != null && unit == 'A' ? (value < 0 ? red18 : (value > 0 ? green18 : dark18)) : dark18;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            spreadRadius: 0.0,
            blurRadius: 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text('${value?.toStringAsFixed(1) ?? '0'} $unit', style: style,),
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
        physics: const NeverScrollableScrollPhysics(),
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
                mainAxisSize: MainAxisSize.max,
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
                  Expanded(child: Text('${data[cellKey].toStringAsFixed(2)} V', style: dark16)),
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

  Future disableWidget() async {
    String removeMac = widget.r.device.remoteId.str;
    final data = ref.read(monitoringWidgets);
    data.removeWhere((key, value) => key == removeMac);
    ref.read(monitoringWidgets.notifier).state = Map.from(data);
  }

  void disconnect() async {
    await disableWidget().then((_) => widget.r.device.disconnect());
  }
  
  Widget options(BuildContext context){
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await renameDevice(context, nameController, mac.toString()).then((_) => setState((){}));
            }, 
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(MdiIcons.fountainPenTip, color: Colors.white,),
                const SizedBox(width: 5,),
                Text('переименовать', style: white14,)
              ],
            )
          ),
      
          const Spacer(),
      
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: disconnect, 
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(MdiIcons.bluetoothOff, color: Colors.white,),
                const SizedBox(width: 5,),
                Text('отключить', style: white14,)
              ],
            )
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child){
        
        final batteryData = ref.watch(bmsDataStreamProvider(widget.r));
        
        return batteryData.when(
          error: (error, stack) {
            disconnect();
            return const SizedBox.shrink();
          }, 
          loading: () => loading(),
          data: (data) {
            // фоновый контейнер
            return Container(
              padding: const EdgeInsets.all(3),
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: Colors.white,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                // контейнер с карточкой
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: handleTap,
                        child: Container(
                          padding: const EdgeInsets.only(left: 8, right: 8, top: 5, bottom: 5),
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$deviceName ${nameController.text.isEmpty ? '' : '\n(${nameController.text})'}', style: dark16,),
                                        Text('MAC: ${mac.toString()}', style: dark12,),
                                      ],
                                    ),
                                  ),
                                  starkDevices.contains(mac) && flavor == 'stark' ? Image.asset('lib/images/stark.png', scale: 3.5) : const SizedBox.shrink(),
                                  Icon(MdiIcons.alertCircle, color: Colors.red),
                                ],
                              ),
                              Padding(
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
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(child: remainIndicator(data['remain'] ?? 0)),
                                        const SizedBox(width: 25,),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 18),
                                          child: RotationTransition(
                                            turns: _iconTurns,
                                            child: const Icon(Icons.expand_more, size: 30,),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          return ClipRect(
                            child: Align(
                              heightFactor: _heightFactor.value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: <Widget>[
                            const Divider(indent: 8, endIndent: 8, thickness: 1.0, height: 1.0,),
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
                            const Divider(indent: 8, endIndent: 8, thickness: 1.0, height: 1.0,),
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
                            const SizedBox(height: 15,),
                            const Divider(indent: 8, endIndent: 8, thickness: 1.0, height: 1.0,),
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
                                child: Center(child: Text('опции', style: dark16,))
                              ),
                            ),
                            const SizedBox(height: 5,),
                            options(context),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              )
            );
          }, 
        );
      }
    );
  }

}