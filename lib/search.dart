import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class s extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Container(
        width: 327,
        height: 56,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: const Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
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
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.text_620,
              style: const TextStyle(
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