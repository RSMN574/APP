import 'package:flutter/material.dart';
class plane extends StatefulWidget {
  const plane({super.key});

  @override
  State<plane> createState() => _planeState();
}

class _planeState extends State<plane> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("plane"),),

    );
  }
}
