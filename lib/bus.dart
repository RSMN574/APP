import 'package:flutter/material.dart';
import 'package:untitled/widget/tab.dart';
import 'database/getData.dart';
 List<String>suggestions = ['apple', 'banana', 'cherry', 'date', 'fig', 'grape'];
class Bus extends StatefulWidget {
  const Bus({super.key});

  @override
  State<Bus> createState() => _BusState();
}

class _BusState extends State<Bus> {

  TextEditingController busIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('公車'),
      ),
      body: Container(
        height: 800,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return suggestions.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                busIdController.text = selection;
                GetApi(busIdController.text);
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: focusNode,
                  onChanged: (text) {
                    if (text.isNotEmpty) {
                      busIdController.text = text;
                      GetApi(busIdController.text); // 當文本變更時調用 API
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                );
              },
              optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32, // 寬度與輸入框匹配
                      color: Colors.white,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return ListTile(
                            title: Text(option),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            tab(
              items: ["路線", "地圖", "城市", "我的最愛"],
              icons: [Icons.home, Icons.map, Icons.location_city, Icons.favorite],
            ),
          ],
        ),
      ),
    );
  }
}
