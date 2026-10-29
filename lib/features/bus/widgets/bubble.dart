import 'package:flutter/material.dart';

class bubble extends StatelessWidget {
  final String plateNum;

  const bubble({
    super.key,
    required this.plateNum,
  });

  @override
  Widget build(BuildContext context) {
    if (plateNum.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('車牌詳細資訊'),
            content: SelectableText(plateNum),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('關閉'),
              ),
            ],
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromRGBO(84, 87, 165, 0.9),
        ),
        child: Text(
          plateNum,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}