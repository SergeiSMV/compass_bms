

// ignore_for_file: unused_field

import 'dart:async';
import 'dart:typed_data';

import 'package:compass/utils/extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../constants/bms_commands.dart';
import '../constants/styles.dart';
import '../providers/bms_provider.dart';
import '../utils/snackbar.dart';



class DeviceScreen extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  const DeviceScreen({super.key, required this.device});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription _charSubscription;

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
        try {
          // _services = await widget.device.discoverServices();
          await widget.device.discoverServices().then((value) {
            startListen(value);
          });
          Snackbar.show(ABC.c, "успешное извлечение сервисов", success: true);
        } catch (e) {
          Snackbar.show(ABC.c, prettyException("ошибка извлечения сервисов:", e), success: false);
        }
      }
      if (mounted) {
        setState(() {});
      }
    });

    // в процессе подключения bool
    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    // устройство отключено bool
    _isDisconnectingSubscription = widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
    
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    _charSubscription.cancel();
    widget.device.disconnect();
    
    super.dispose();
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "успешное извлечение сервисов", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("ошибка извлечения сервисов:", e), success: false);
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }


  Future startListen(List services) async {
    List<int> package = [];
    for (BluetoothService service in services) {
      if (service.uuid.toString() == 'ffe0') {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid.toString() == 'ffe1') {
            await characteristic.write(deviceInfo, withoutResponse: false);
            await characteristic.setNotifyValue(true).then((_) async {
              await characteristic.write(cellInfo, withoutResponse: false);
              _charSubscription = characteristic.lastValueStream.listen((value) async {
                if(value[0] == 85){
                  if(package.isEmpty){
                    package.addAll(value);
                  } else {
                    Uint8List input = Uint8List.fromList(package);
                    ByteData bd = input.buffer.asByteData();
                    try {
                      Map data = {};
                      for (int i = 0; i < 32; i++){
                        int result = bd.getInt16(6 + 2 * i, Endian.little);
                        result > 0 ? data['cell ${i + 1}'] = '${result / 1000} V' : null;
                      }

                      int temp1 = bd.getInt16(162, Endian.little);
                      temp1 > 0 ? data['temp1'] = '${temp1 / 10} °C' : null;

                      int temp2 = bd.getInt16(164, Endian.little);
                      temp2 > 0 ? data['temp2'] = '${temp2 / 10} °C' : null;

                      ref.read(dataProvider.notifier).state = data;

                    } catch (e) {
                      null;
                    }
                    package.clear();
                    package.addAll(value);
                  }
                } else {
                  package.addAll(value);
                }
              });
            });
          }
        }
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color(0xFFf68800),
          centerTitle: true,
          title: Text(widget.device.platformName, style: dark18,),
      ),
      body: Consumer(
        builder: (context, ref, child) {
      
          final data = ref.watch(dataProvider);
      
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          spreadRadius: 0.0,
                          blurRadius: 0.5,
                          offset: const Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Container(
                                padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 20),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: <Color>[
                                      const Color(0xFFf68800),
                                      const Color(0xFFf68800).withOpacity(0.6),
                                      const Color(0xFFf68800).withOpacity(0.3),
                                      const Color(0xFFf68800).withOpacity(0.0)
                                    ],
                                  ),
                                ),
                                child: Text('напряжение', style: dark16,)
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ...List.generate(32, (index) {
                              String cellKey = 'cell ${index + 1}';
                              return data.containsKey(cellKey) ? 
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(MdiIcons.battery, color: Colors.grey.shade800, size: 30,),
                                        Text('${index + 1}', style: white10,)
                                        // CircleAvatar(radius: 11, backgroundColor: const Color(0xFFf68800), child: Text('${index + 1}', style: dark10,),),
                                      ],
                                    ),
                                    
                                    const SizedBox(width: 10,),
                                    Text('${data[cellKey]}', style: dark16,),
                                  ],
                                ),
                              ) 
                              : const SizedBox.shrink();
                            }),
                          ],
                        ),

                        const VerticalDivider(
                          color: Colors.black,
                          thickness: 2,
                          width: 60,
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Container(
                                padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 20),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: <Color>[
                                      const Color(0xFFf68800),
                                      const Color(0xFFf68800).withOpacity(0.6),
                                      const Color(0xFFf68800).withOpacity(0.3),
                                      const Color(0xFFf68800).withOpacity(0.0)
                                    ],
                                  ),
                                ),
                                child: Text('температура', style: dark16,)
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ...List.generate(2, (index) {
                              String tempKey = 'temp${index + 1}';
                              return data.containsKey(tempKey) ? 
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Icon(MdiIcons.thermometerHigh, color: Colors.grey.shade800, size: 30,),
                                      Positioned(
                                        top: 12,
                                        right: 0,
                                        child: Text('${index + 1}', style: dark12,)
                                      )
                                    ],
                                  ),
                                  
                                  const SizedBox(width: 10,),
                                  Text('${data[tempKey]}', style: dark16,),
                                ],
                              ) 
                              : const SizedBox.shrink();
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                  
                const SizedBox(height: 10,),
                /*
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text('температура:', style: dark14,),
                        ),
                        const SizedBox(height: 10,),
                        ...List.generate(2, (index) {
                          String tempKey = 'temp${index + 1}';
                          return data.containsKey(tempKey) ? 
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Icon(MdiIcons.thermometerHigh, color: Colors.black87, size: 30,),
                                  Positioned(
                                    top: 12,
                                    right: 0,
                                    child: Text('${index + 1}', style: dark12,)
                                  )
                                ],
                              ),
                              
                              const SizedBox(width: 10,),
                              Text('${data[tempKey]}', style: dark16,),
                            ],
                          ) 
                          : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ),
                */
              ],
            ),
          );
        }
      ),
    );
  }
}
