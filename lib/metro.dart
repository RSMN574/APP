import 'package:flutter/material.dart';
class metro extends StatefulWidget {
  const metro({super.key});

  @override
  State<metro> createState() => _metroState();
}

class _metroState extends State<metro> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("metro"),),

    );
  }
}
