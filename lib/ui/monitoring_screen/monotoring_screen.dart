
import 'package:compass_bms_app/ui/static_ui/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Center(
        child: Text(
          'MonitoringScreen',
          style: darkBlue14,
        ),
      ),
    );
  }
}
