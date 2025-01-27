

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

abstract class FFE0ServiceRepository {

  Future<Stream<Map<String, dynamic>>> deviceStreamData(FlutterReactiveBle ble, QualifiedCharacteristic targetCharacteristic);

}