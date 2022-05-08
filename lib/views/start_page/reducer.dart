import 'package:fish_redux/fish_redux.dart';

import 'action.dart';
import 'state.dart';

Reducer<StartPageState> buildReducer() {
  return asReducer(
    <Object, Reducer<StartPageState>>{
      StartPageAction.action: _onAction,
      StartPageAction.setIsFirst: _setIsFirst,
      StartPageAction.setIsLoading: _onSetIsLoading,
    },
  );
}

StartPageState _onAction(StartPageState state, Action action) {
  final StartPageState newState = state.clone();
  return newState;
}

StartPageState _setIsFirst(StartPageState state, Action action) {
  final bool _isFirst = action.payload;
  final StartPageState newState = state.clone();
  newState.isFirstTime = _isFirst; //true;
  return newState;
}

StartPageState _onSetIsLoading(StartPageState state, Action action) {
  final StartPageState newState = state.clone();
  newState.isLoading = action.payload;
  return newState;
}
