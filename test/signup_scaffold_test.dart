import 'package:dio/dio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_saver_client/common/config.dart';
import 'package:pet_saver_client/common/http-common.dart';
import 'package:pet_saver_client/common/sharePerfenceService.dart';
import 'package:pet_saver_client/models/user.dart';
import 'package:pet_saver_client/pages/editPost.dart';
import 'package:pet_saver_client/pages/home.dart';
import 'package:pet_saver_client/pages/mypost.dart';
import 'package:pet_saver_client/pages/navigator.dart';
import 'package:pet_saver_client/pages/notifications.dart';
import 'package:pet_saver_client/pages/signup_scaffold.dart';
import 'package:pet_saver_client/router/delegate.dart';
import 'package:pet_saver_client/router/parsed_route.dart';
import 'package:pet_saver_client/router/parser.dart';
import 'package:pet_saver_client/router/route_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_image_mock/network_image_mock.dart';
// import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:firebase_database/firebase_database.dart';


import 'data.dart';
import 'mock.dart';

class MockDatabase extends Mock implements FirebaseDatabase{}

void main() {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final RouteState _routeState;
  late final SimpleRouterDelegate _routerDelegate;
  late final TemplateRouteParser _routeParser;  
  late FirebaseDatabase firebaseDatabase;
  setupFirebaseAuthMocks();

  Future<ParsedRoute> _guard(ParsedRoute from) async {
    return from;
  }

  setUpAll(() async {
    await Firebase.initializeApp();
 
    // firebaseDatabase = MockFirebaseDatabase();
    _routeParser = TemplateRouteParser(
      allowedPaths: [
        '/',
        '/splash',
        '/notifications',
        '/signin',
        '/signup',
        '/post',
        '/settings',
        '/mypost',
        '/new/post',
        '/edit/post/:id',
        '/post/:id'
      ],
      guard: _guard,
    );
    _routeState = RouteState(_routeParser);

    _routerDelegate = SimpleRouterDelegate(
      routeState: _routeState,
      navigatorKey: _navigatorKey,
      builder: (context) => MyNavigator(
        navigatorKey: _navigatorKey,
      ),
    );
  });
  Widget createWidgetForTesting({required Widget child}) {
    return ProviderScope(
      child: MaterialApp(
          builder: EasyLoading.init(),
          home: RouteStateScope(
            notifier: _routeState,
            child: child,
          )),
    );
  }

  testWidgets('load siup up page mode 1', (tester) async {
    
    Config.isTest = true;
    final user = MockUser(
      isAnonymous: false,
      uid: 'BC6iAMeUjbcWRc7ux3OtpbtSdhY2',
      email: 'ikouhaha888@gmail.com',
      displayName: 'Bob',
    );
    final auth = MockFirebaseAuth(mockUser: user);

    var dio = Dio();
    var dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;
    Http.setDio(dio: dio);
    Http.setAutoPopup(autoPopup: false);


    //when(FirebaseAuth.instance.currentUser).thenAnswer((_) => auth.currentUser);

    SharedPreferencesService.sharedPrefs =
        await SharedPreferences.getInstance();
    UserModel profile = UserModel(
        id: 1,
        email: 'test@gmail.com',
        username: 'test',
        displayName: 'test',
        role: 'user',
        avatarUrl:
            'https://lh3.googleusercontent.com/a/AATXAJyzetG1ehaZy7LI0Wanz3LIuL87iETNNtLrIxPo=s96-c',
        dateRegistered: DateTime.now());
    SharedPreferencesService.saveProfile(profile);
    MockDatabase db = MockDatabase();
    
     await tester.pumpWidget(createWidgetForTesting(child:  SignupScaffold()));
    await tester.pump(Duration(seconds: 5));
    for (int i = 0; i < 5; i++) {
      // because pumpAndSettle doesn't work with riverpod
      await tester.pump(Duration(seconds: 1));
    }
    

    // Config.testMode = "1";
    // expect(find.widgetWithIcon(FloatingActionButton, Icons.add), findsOneWidget);
    //   await tester.pump(Duration(seconds: 5));
    //  await tester.tap(find.byType(FloatingActionButton));
    //  await tester.pump();
    
  });


}
