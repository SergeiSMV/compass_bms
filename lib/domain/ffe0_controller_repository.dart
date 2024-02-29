import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class FFE0Repository {

  Future<StreamSubscription?> connect(ScanResult r, WidgetRef ref);

}