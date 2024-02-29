


import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../constants/styles.dart';
import 'monitoring_screen.dart';
import 'scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _selectedIndex = 0;
  final List<String> appBarTitles = const['BMS устройства', 'Мониторинг'];
  final List<Widget> screens = const[ScanScreen(), MonitoringScreen()];

  Widget bottomNavBar(){
    return GNav(
      textStyle: dark14,
      tabMargin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      gap: 8,
      activeColor: Colors.black,
      iconSize: 25,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      duration: const Duration(milliseconds: 400),
      tabBackgroundColor: Colors.white,
      color: Colors.white,
      tabs: [
        GButton(
          // icon: MdiIcons.dns,
          icon: MdiIcons.batteryBluetooth,
          text: 'устройства',
        ),
        GButton(
          // icon: MdiIcons.distributeHorizontalCenter,
          icon: MdiIcons.fileTree,
          text: 'мониторинг',
        ),
      ],
      selectedIndex: _selectedIndex,
      onTabChange: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFf68800),
        centerTitle: true,
        title: Text(appBarTitles[_selectedIndex], style: dark18,),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: bottomNavBar(),
    );
  }
}