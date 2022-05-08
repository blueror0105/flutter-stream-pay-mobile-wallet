import 'package:fish_redux/fish_redux.dart';

enum StartPageAction {
  action,
  setIsFirst,
  onStart,
  setIsLoading,
}

class StartPageActionCreator {
  static Action onAction() {
    return const Action(StartPageAction.action);
  }

  static Action onStart() {
    return const Action(StartPageAction.onStart);
  }

  static Action setIsFirst(bool isFirst) {
    return Action(StartPageAction.setIsFirst, payload: isFirst);
  }

  static Action onSetIsLoading(bool payload) {
    return Action(StartPageAction.setIsLoading, payload: payload);
  }
}
