import 'package:compass_bms_app/_old/old_constants/old_styles.dart';
import 'package:compass_bms_app/ui/static_ui/colors.dart';
import 'package:flutter/material.dart';

class TopMessage {
  static void show(BuildContext context, String message, [IconData? icon]) {
    final overlay = Overlay.of(context); // Проверяем наличие Overlay

    late OverlayEntry overlayEntry;

    // Создаем анимационный контроллер
    final animationController = AnimationController(
      vsync: Navigator.of(context), // Используем Navigator для TickerProvider
      duration: const Duration(milliseconds: 400),
    );

    // Анимация перемещения
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Снаружи экрана
      end: Offset.zero, // В области экрана
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    // Анимация прозрачности
    final opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    ));

    // Создаем OverlayEntry
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 23,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: primaryAppColor, size: 20,),
                        const SizedBox(width: 10,),
                      ],
                      Flexible(
                        child: Text(
                          message,
                          style: orange13,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Вставляем OverlayEntry
    overlay.insert(overlayEntry);

    // Запускаем анимацию появления
    animationController.forward();

    // Удаляем сообщение через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      animationController.reverse().whenComplete(() {
        overlayEntry.remove(); // Удаляем сообщение из Overlay
        animationController.dispose(); // Освобождаем ресурсы
      });
    });
  }
}
