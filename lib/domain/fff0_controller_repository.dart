

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class FFF0Repository {

  Future<void> connect(ScanResult r);

  Future<Stream<Map<String, dynamic>>> streamData(ScanResult r);

  void decodePackage(List<int> package);

  void decodeCellVoltage(List<int> package);

  void decodeTemperature(List<int> package);

  void decodeSOC(List<int> package);

  int calculatedCrc(List<int> requestData);
  
  void disconnect();

}