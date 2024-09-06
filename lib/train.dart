import 'package:flutter/material.dart';
class train extends StatefulWidget {
  const  train({super.key});

  @override
  State<train> createState() => _trainState();
}

class _trainState extends State<train> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("train"),),

    );
  }
}
