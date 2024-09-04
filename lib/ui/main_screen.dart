import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';

import '../constants/styles.dart';
import '../main.dart';
import '../providers/bms_provider.dart';
import 'monitoring_screen.dart';
import 'scan_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {

  Widget bottomNavBar(){
    return GNav(
      backgroundColor: const Color(0xFF192f4c).withOpacity(0.7),
      textStyle: dark14,
      tabMargin: const EdgeInsets.only(left: 20, right: 20, bottom: 10, top: 10),
      gap: 8,
      activeColor: Colors.black,
      iconSize: 25,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      duration: const Duration(milliseconds: 400),
      tabBackgroundColor: Colors.white,
      color: flavor == 'oem' ? const Color(0xFF42fff9) : Colors.white,
      tabs: [
        GButton(
          icon: MdiIcons.batteryBluetooth,
          text: 'устройства',
        ),
        GButton(
          icon: MdiIcons.fileTree,
          text: 'мониторинг',
        ),
      ],
      onTabChange: (index) {
        ref.read(screenIndexProvider.notifier).state = index;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      barrierColor: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.all(20.0),
      borderColor: Colors.transparent,
      indicatorColor: flavor == 'oem' ? const Color(0xFF42fff9) : Colors.orange,
      child: Builder(
        builder: (context) {
          final progress = ProgressHUD.of(context);
          return Scaffold(
            backgroundColor: Colors.black,
            body: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: flavor == 'oem' ? const BoxDecoration(
                image: DecorationImage(
                  opacity: 0.5,
                  image: AssetImage('lib/images/oem_bg.png'),
                  fit: BoxFit.cover,
                ),
              ) : const BoxDecoration(
                image: DecorationImage(
                  opacity: 1,
                  image: AssetImage('lib/images/bonding.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final List<Widget> screens = [ScanScreen(progress: progress), const MonitoringScreen()];
                  final selectedIndex = ref.watch(screenIndexProvider);
                  return screens[selectedIndex];
                }
              ),
            ),
            bottomNavigationBar: bottomNavBar(),
          );
        }
      ),
    );
  }
}