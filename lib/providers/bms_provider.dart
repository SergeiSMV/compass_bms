
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/bms_services.dart';
import '../data/ffe0_controller_implements.dart';
import '../data/fff0_controller_implements.dart';

final dataProvider = StateProvider<Map>((ref) {
  return {};
});

final monitoringWidgets = StateProvider<Map<String, dynamic>>((ref) {
  return {};
});

final screenIndexProvider = StateProvider((ref) => 0);

final bmsDataStreamProvider = StreamProvider.family.autoDispose<Map<String, dynamic>, ScanResult>((ref, r) async* {
  dynamic parrenClass;
  var adv = r.advertisementData;
  List<Guid> services = adv.serviceUuids;
  for (var s in services){
    if (requiredServices.contains(s)){
      if (s.toString() == 'ffe0'){
        parrenClass = FFE0Implements();
      }
      if (s.toString() == 'fff0'){
        parrenClass = FFF0Implements();
      }
    }
  }
  ref.onDispose(() {
    parrenClass.disconnect();
  });
  yield* await parrenClass.streamData(r);
});

