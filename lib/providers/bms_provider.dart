
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/loger.dart';
import '../data/ffe0_controller_implements.dart';

final dataProvider = StateProvider<Map>((ref) {
  return {};
});

final monitoringProvider = StateProvider<Map>((ref) {
  return {};
});

final monitoringWidgets = StateProvider<Map<String, Widget>>((ref) {
  return {};
});

final screenIndexProvider = StateProvider((ref) => 0);

final bmsDataStreamProvider = StreamProvider.family.autoDispose<Map<String, dynamic>, ScanResult>((ref, r) async* {
  FFE0Implements ffe0Implements = FFE0Implements();
  ref.onDispose(() {
    ffe0Implements.disconnect();
  });
  yield* await ffe0Implements.streamData(r);
});

