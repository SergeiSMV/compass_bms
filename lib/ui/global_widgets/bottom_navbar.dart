
import 'package:compass_bms_app/riverpod/riverpod.dart';
import 'package:compass_bms_app/ui/static_ui/colors.dart';
import 'package:compass_bms_app/ui/static_ui/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';



class BottomNavbar extends ConsumerStatefulWidget {
  const BottomNavbar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends ConsumerState<BottomNavbar> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5, left: 5, right: 5),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(30),
          ),
          child: GNav(
            backgroundColor: Colors.black.withOpacity(0.4),
            textStyle: darkBlue14,
            tabMargin: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 5),
            gap: 8,
            activeColor: Colors.black,
            iconSize: 25,
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: primaryAppColor,
            color: Colors.white,
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
              ref.read(bottomBarIndexProvider.notifier).setIndex(index);
            },
          ),
        ),
      ),
    );
  }
}