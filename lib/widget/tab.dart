import 'package:flutter/material.dart';






class tab extends StatefulWidget {

  final List<IconData> icons;
  final List<String> items;
  tab({
    required this.items,
    required this.icons,


  });

  @override
  State<tab> createState() => tabState();
}

class tabState extends State<tab> {



  @override
  Widget build(BuildContext context) {
    return
      Container(


          margin: const EdgeInsets.all(5),
          child: Column(
              children: [

                /// Tab Bar
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.items.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (ctx, index) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  current = index;
                                });
                                pageController.animateToPage(
                                  current,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.ease,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.all(5),
                                width: 100,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: current == index
                                      ? Colors.white70
                                      : Colors.white54,
                                  borderRadius: current == index
                                      ? BorderRadius.circular(12)
                                      : BorderRadius.circular(7),
                                  border: current == index
                                      ? Border.all(
                                      color: Colors.deepPurpleAccent,
                                      width: 2.5)
                                      : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.icons[index],
                                        size: current == index ? 23 : 20,
                                        color: current == index
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                      ),
                                      Text(
                                        widget.items[index],

                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: current == index,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                    color: Colors.deepPurpleAccent,
                                    shape: BoxShape.circle),
                              ),
                            )
                          ],
                        );
                      }),
                ),

                /// MAIN BODY
                Container(
                  margin: const EdgeInsets.only(top: 30),
                  width: double.infinity,
                  height: 550,
                  child: PageView.builder(
                    itemCount:  widget.icons.length,
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icons[current],
                            size: 200,
                            color: Colors.deepPurpleAccent,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${ widget.items[current]} Tab Content",)

                        ],
                      );
                    },
                  ),
                )
              ]));



  }
  /// List of Tab Bar Item


  /// List of body icon

  int current = 0;
  PageController pageController = PageController();
  }
