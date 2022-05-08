import 'package:fish_redux/fish_redux.dart';
import 'package:flutter/material.dart';

class StartPageState implements Cloneable<StartPageState> {
  PageController pageController;
  bool isFirstTime;
  bool isLoading = true;

  @override
  StartPageState clone() {
    return StartPageState()
      ..pageController = pageController
      ..isFirstTime = isFirstTime
      ..isLoading = isLoading;
  }
}

StartPageState initState(Map<String, dynamic> args) {
  return StartPageState();
}
