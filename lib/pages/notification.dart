import 'package:flutter/material.dart';
class notification extends StatefulWidget {


  @override
  State<notification> createState() => _notificationState();
}

class _notificationState extends State<notification> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('通知'),
      ),


    );
  }
}
