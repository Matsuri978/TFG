import 'package:flutter/material.dart';

import 'ar_screen.dart';
//import 'prueba.dart';
import 'live_position_screen.dart';

class HomeSwipeScreen extends StatefulWidget {
  const HomeSwipeScreen({Key? key}) : super(key: key);

  @override
  State<HomeSwipeScreen> createState() => _HomeSwipeScreenState();
}

class _HomeSwipeScreenState extends State<HomeSwipeScreen> {
  final PageController _pageController = PageController(initialPage: 0);

  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
               KeepAliveWrapper(
                child: LivePositionScreen(),
              ),

              KeepAliveWrapper(
                child: ARScreen(),
              ),
            ],
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0),
                const SizedBox(width: 8),
                _buildDot(1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPageIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 10,
      width: isActive ? 20 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          )
        ],
      ),
    );
  }
}


class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}