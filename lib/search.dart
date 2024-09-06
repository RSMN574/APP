import 'package:flutter/material.dart';

class Frame9 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Container(
          width: 327,
          height: 56,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: Color(0xFFFAFAFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: SizedBox(width: 24, height: 24, child: Stack()),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text(
                '搜尋',
                style: TextStyle(
                  color: Color(0xFF8696BB),
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  height: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}