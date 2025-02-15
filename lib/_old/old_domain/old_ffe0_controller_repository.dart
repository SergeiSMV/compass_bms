import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class FFE0Repository {

  Future<void> connect(ScanResult r);

  Future<Stream<Map<String, dynamic>>> streamData(ScanResult r);

  Map<String, dynamic> decodePackage(List<int> package);
  
  void disconnect();

}