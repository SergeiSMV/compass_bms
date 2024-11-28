import 'dart:async';

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../constants/styles.dart';
import 'main_scaffold/main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 4), () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScaffold()));
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.7,
              child: Image.asset('lib/images/stark.png', scale: 4)
            ),
            const SizedBox(height: 10,),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'первая интелектуальная батарея',
                  textStyle: grey16,
                  speed: const Duration(milliseconds: 90),
                ),
              ],
              totalRepeatCount: 1,
              pause: const Duration(milliseconds: 1300),
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
            ),
          ],
        ),
      ),
    );
  }
}