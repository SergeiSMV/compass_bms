import 'package:hive_flutter/hive_flutter.dart';

import '../old_domain/old_hive_repository.dart';

class HiveImplements extends HiveRepository{
  
  final Box hive = Hive.box('hiveStorage');

  // сохранить имя устройства
  @override
  Future<void> saveDeviceName(String name, String mac) async {
    Map devices = await hive.get('devices', defaultValue: {});
    devices[mac] = name;
    await hive.put('devices', devices);
  }


  // получить имя устройства
  @override
  Future<String> getDeviceName(String mac) async {
    Map devices = await hive.get('devices', defaultValue: {});
    return devices[mac] ?? '';
  }


}