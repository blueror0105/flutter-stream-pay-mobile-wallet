import 'package:com.floridainc.dosparkles/actions/api/graphql_client.dart';
import 'package:com.floridainc.dosparkles/views/login_page/action.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fish_redux/fish_redux.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'action.dart';
import 'state.dart';
import 'package:com.floridainc.dosparkles/actions/app_config.dart';

import 'package:com.floridainc.dosparkles/models/models.dart';

import 'package:com.floridainc.dosparkles/globalbasestate/store.dart';
import 'package:com.floridainc.dosparkles/globalbasestate/action.dart';

import 'package:com.floridainc.dosparkles/actions/user_info_operate.dart';
import 'package:com.floridainc.dosparkles/actions/stores_info_operate.dart';

Effect<StartPageState> buildEffect() {
  return combineEffects(<Object, Effect<StartPageState>>{
    StartPageAction.action: _onAction,
    StartPageAction.onStart: _onStart,
    Lifecycle.build: _onBuild,
    Lifecycle.initState: _onInit,
    Lifecycle.dispose: _onDispose,
  });
}

void _onAction(Action action, Context<StartPageState> ctx) {}

Future _loadData(BuildContext context) async {
  await AppConfig.instance.init(context);
  await UserInfoOperate.whenAppStart();
  await StoresInfoOperate.whenAppStart();

  GlobalStore.store
      .dispatch(GlobalActionCreator.setShoppingCart(new List<CartItem>()));
}

void _onInit(Action action, Context<StartPageState> ctx) async {
  ctx.dispatch(StartPageActionCreator.onSetIsLoading(true));

  FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.instance.setAutoInitEnabled(true);

  ctx.state.pageController = PageController();

  await _loadData(ctx.context);

  SharedPreferences.getInstance().then((_p) async {
    final savedToken = _p.getString('jwt') ?? '';
    if (savedToken.isEmpty) {
      ctx.dispatch(StartPageActionCreator.setIsFirst(true));
      ctx.dispatch(StartPageActionCreator.onSetIsLoading(false));
      return null;
    }

    final _isFirst = _p.getBool('firstStart') ?? true;
    if (!_isFirst) {
      await _pushToSignInPage(ctx);
    } else
      ctx.dispatch(StartPageActionCreator.setIsFirst(_isFirst));
  });
}

void _onDispose(Action action, Context<StartPageState> ctx) {
  ctx.state.pageController.dispose();
}

void _onBuild(Action action, Context<StartPageState> ctx) {}

void _onStart(Action action, Context<StartPageState> ctx) async {
  SharedPreferences.getInstance().then((_p) {
    _p.setBool('firstStart', false);
  });
  await _pushToSignInPage(ctx);
}

Future _pushToSignInPage(Context<StartPageState> ctx) async {
  SharedPreferences.getInstance().then((_p) async {
    String referralLink = _p.getString("referralLink") ?? '';
    String resetPasswordCode = _p.getString("resetPasswordCode") ?? '';
    final savedToken = _p.getString('jwt') ?? '';

    if (referralLink != null && referralLink.isNotEmpty) {
      Navigator.of(ctx.context).pushNamed('registrationpage');
      return;
    }

    if (resetPasswordCode != null && resetPasswordCode.isNotEmpty) {
      Navigator.of(ctx.context).pushNamed('reset_passwordpage');
      return;
    }

    if (savedToken.isNotEmpty) {
      await UserInfoOperate.whenLogin(savedToken.toString(), ctx.context);
      await BaseGraphQLClient.instance.me();
      _goToMain(ctx);
    } else {
      Navigator.of(ctx.context).pushReplacementNamed('loginpage');
    }
  });
}

Future<void> _goToMain(Context<StartPageState> ctx) async {
  ctx.dispatch(StartPageActionCreator.onSetIsLoading(true));

  var globalState = GlobalStore.store.getState();

  await checkUserReferralLink(globalState.user);

  await checkUserPhoneNumber(globalState.user, ctx.context);

  if (globalState.storesList != null && globalState.storesList.length > 0) {
    for (var i = 0; i < globalState.storesList.length; i++) {
      var store = globalState.storesList[i];
      if (globalState.user.storeFavorite != null &&
          globalState.user.storeFavorite['id'] == store.id) {
        GlobalStore.store.dispatch(
          GlobalActionCreator.setSelectedStore(store),
        );
        Navigator.of(ctx.context).pushReplacementNamed('storepage');
        return null;
      }
    }
  }

  Navigator.of(ctx.context).pushReplacementNamed('storeselectionpage');

  ctx.dispatch(StartPageActionCreator.onSetIsLoading(false));
}

Future checkUserReferralLink(AppUser globalUser) async {
  if (globalUser.referralLink == null || globalUser.referralLink == '') {
    BranchUniversalObject buo = BranchUniversalObject(
      canonicalIdentifier: 'flutter/branch',
      title: 'Example Branch Flutter Link',
      imageUrl: 'https://miro.medium.com/max/1000/1*ilC2Aqp5sZd1wi0CopD1Hw.png',
      contentDescription:
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      keywords: ['Plugin', 'Branch', 'Flutter'],
      publiclyIndex: true,
      locallyIndex: true,
      expirationDateInMilliSec:
          DateTime.now().add(Duration(days: 365)).millisecondsSinceEpoch,
    );
    FlutterBranchSdk.registerView(buo: buo);

    BranchLinkProperties lp = BranchLinkProperties(
        channel: 'google',
        feature: 'referral',
        alias: 'referralToken=${Uuid().v4()}',
        stage: 'new share',
        campaign: 'xxxxx',
        tags: ['one', 'two', 'three']);
    lp.addControlParam('url', 'http://www.google.com');
    lp.addControlParam('url2', 'http://flutter.dev');

    BranchResponse response =
        await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
    if (response.success) {
      try {
        await BaseGraphQLClient.instance
            .setUserReferralLink(globalUser.id, response.result);

        globalUser.referralLink = response.result;
        GlobalStore.store.dispatch(GlobalActionCreator.setUser(globalUser));
      } catch (e) {
        print(e);
      }
    } else {
      print('Error : ${response.errorCode} - ${response.errorMessage}');
    }
  }
}

Future checkUserPhoneNumber(AppUser globalUser, context) async {
  final result =
      await BaseGraphQLClient.instance.checkUserFields(globalUser.id);
  if (result.hasException) print(result.exception);

  if (result.data['users'][0]['phoneNumber'] == null) {
    await Navigator.of(context).pushNamed('addphonepage', arguments: null);
  }
}
