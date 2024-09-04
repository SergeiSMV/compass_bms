
import 'package:flutter/material.dart';

import '../constants/styles.dart';
import '../data/hive_implements.dart';


Future renameDevice(BuildContext mainContext, TextEditingController controller, String mac){
  return showModalBottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: mainContext, 
    builder: (context){
      return Container(
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0)),
          color: Color(0xFFe3efff),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 35, right: 35, top: 50),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.transparent
                  ),
                  color: Colors.white,
                ),
                height: 45,
                width: 300,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: dark15,
                  minLines: 1,
                  obscureText: false,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: grey15,
                    hintText: 'новое имя устройства',
                    prefixIcon: const IconTheme(data: IconThemeData(color: Color(0xFF687797)), child: Icon(Icons.edit)),
                    isCollapsed: true
                  ),
                  onSubmitted: (_) {  },
                ),
              ),
            ),

            const SizedBox(height: 20,),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await HiveImplements().saveDeviceName(controller.text, mac).then((value) => Navigator.pop(context));
              }, 
              child: Padding(
                padding: const EdgeInsets.only(left: 90, right: 90),
                child: Text('сохранить', style: white14,),
              )
            ),      
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: const SizedBox(height: 30),
            ),
          ],
        ),
      );


    }
  );
}