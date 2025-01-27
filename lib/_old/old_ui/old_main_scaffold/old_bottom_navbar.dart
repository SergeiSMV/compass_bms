
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../old_constants/old_styles.dart';
import '../../old_main_app.dart';
import '../../old_providers/old_bms_provider.dart';

Widget bottomNavBar(WidgetRef ref){
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 5, right: 5),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(30),
        ),
        child: GNav(
          backgroundColor: Colors.black.withOpacity(0.4),
          textStyle: dark14,
          tabMargin: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 5),
          gap: 8,
          activeColor: Colors.black,
          iconSize: 25,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
          duration: const Duration(milliseconds: 400),
          tabBackgroundColor: flavor == 'oem' ? const Color(0xFF42fff9) : const Color(0xFFf68800),
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
        ),
      ),
    ),
  );
}