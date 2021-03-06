import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pet_saver_client/common/sharePerfenceService.dart';
import 'package:pet_saver_client/components/change_pwd_card.dart';
import 'package:pet_saver_client/components/profile_card.dart';
import 'package:pet_saver_client/router/route_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SettingPage extends ConsumerStatefulWidget {
  User? user;
  SettingPage({
    Key? key,
    this.user,
  }) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}


class _SettingScreenState extends ConsumerState<SettingPage> {
 
  @override
  void initState() {
    super.initState();
  
    
  }

  @override
  void dispose() {
    super.dispose();
  }

  // void _handleBookTapped(Book book) {
  //   _routeState.go('/book/${book.id}');
  // }

  User? get user => widget.user??FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
      if (user == null) {
      RouteStateScope.of(context).go("/signin");
      return Container();
    }
    var profile = SharedPreferencesService.getProfile()!;
     
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(38.0, 0, 38.0, 8.0),
                child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ProfileCard(user: profile),
                        ChangePwdCard(
                          key: const Key("pwd"),
                          user: profile
                         
                        ),
                        const _LogoutButton(),
                        //const _SignUpButton(),
                      ],
                    ))))
      ]),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        // print("------status-----");
        // print(state.status.isValidated);

        return Padding(
            padding: EdgeInsets.only(top: 20),
            child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Logout'),
                disabledColor: Colors.blueAccent.withOpacity(0.6),
                color: Colors.redAccent,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  RouteStateScope.of(context).go("/");
                }));
      },
    );
  }
}
