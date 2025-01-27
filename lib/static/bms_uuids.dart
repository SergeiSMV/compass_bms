import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// список сервисов для работы с BMS Jikong и Daly
List<Uuid> serviceUUIDS = [
  Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb"), // ffe0 Jikong
  Uuid.parse("0000fff0-0000-1000-8000-00805f9b34fb"), // fff0 Daly
];



// список характеристик для работы с BMS Jikong и Daly
List<Uuid> characteristicUUIDS = [
  Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb"), // ffe0 Jikong
];
