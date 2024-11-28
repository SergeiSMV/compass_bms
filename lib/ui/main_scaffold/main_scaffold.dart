
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';

import '../../main.dart';
import '../../providers/bms_provider.dart';
import '../monitoring_screen.dart';
import '../scan_screen.dart';
import 'bottom_navbar.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScaffold> {
  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      barrierColor: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.all(20.0),
      borderColor: Colors.transparent,
      indicatorColor: flavor == 'oem' ? const Color(0xFF42fff9) : Colors.orange,
      child: Builder(
        builder: (context) {
          final progressHUD = ProgressHUD.of(context);
          return Scaffold(
            extendBody: true,
            backgroundColor: Colors.black,
            body: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: flavor == 'oem' ? 
                const BoxDecoration(
                  image: DecorationImage(
                    opacity: 0.5,
                    image: AssetImage('lib/images/oem_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ) 
                : 
                const BoxDecoration(
                  image: DecorationImage(
                    opacity: 1,
                    image: AssetImage('lib/images/bonding.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              child: Consumer(
                builder: (context, ref, child) {
                  final List<Widget> screens = [ScanScreen(progressHUD: progressHUD), const MonitoringScreen()];
                  final selectedIndex = ref.watch(screenIndexProvider);
                  return screens[selectedIndex];
                }
              ),
            ),
            bottomNavigationBar: bottomNavBar(ref),
          );
        }
      ),
    );
  }
}