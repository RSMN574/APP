import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Buslist extends StatefulWidget {
  final List suggestions;

  Buslist( {
    required this.suggestions
});

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(

            title: Text(widget.suggestions[index]["RouteName"]),
            subtitle: Text(widget.suggestions[index]['DepartureStopNameZh']!),

            onTap: () {
              // Add your navigation or functionality here
            },
          ),
        );
      },
    );;
  }
}
