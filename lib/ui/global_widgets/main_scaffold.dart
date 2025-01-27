
import 'package:compass_bms_app/riverpod/riverpod.dart';
import 'package:compass_bms_app/ui/global_widgets/top_message.dart';
import 'package:compass_bms_app/ui/scan_screen/scan_button.dart';
import 'package:compass_bms_app/ui/static_ui/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../static/screens_list.dart';
import '../static_ui/text_styles.dart';
import 'bottom_navbar.dart';


class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScaffold> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {

    final currentBottomBarIndex = ref.watch(bottomBarIndexProvider);

    return Builder(
      builder: (context) {
        return Builder(
          builder: (context) {

            final message = ref.watch(messageProvider);

            if (message.isNotEmpty) {
            // Выполняем действие после завершения текущей сборки
            WidgetsBinding.instance.addPostFrameCallback((_) {
                TopMessage.show(context, message);
              });
            }

            return Scaffold(
              extendBody: true,
              appBar: AppBar(
                backgroundColor: primaryAppColor,
                centerTitle: true,
                title: Consumer(
                  builder: (context, ref, child) {
                    final title = ref.watch(appBarTitleProvider);
                    return Text(title, style: darkBlueTitle,);
                  }
                ),
                actions: [
                  currentBottomBarIndex == 0 ?
                  ScanButton() : const SizedBox.shrink()
                ],
              ),
              body: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    opacity: 1,
                    image: AssetImage('lib/images/bonding.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    return screensList[currentBottomBarIndex];
                  }
                ),
              ),
              bottomNavigationBar: const BottomNavbar(),
            );
          }
        );
      }
    );
  }
}