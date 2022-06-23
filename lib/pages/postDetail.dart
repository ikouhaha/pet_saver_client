import 'dart:convert';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pet_saver_client/common/config.dart';
import 'package:pet_saver_client/common/helper.dart';
import 'package:pet_saver_client/common/http-common.dart';
import 'package:pet_saver_client/common/validations.dart';
import 'package:pet_saver_client/components/auth_text_field.dart';
import 'package:pet_saver_client/models/post.dart';
import 'package:pet_saver_client/providers/global_provider.dart';
import 'package:pet_saver_client/router/route_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_database/firebase_database.dart';



final _getDataProvider = 
    FutureProvider.autoDispose.family<PostModel, String>((ref,id) async {
 
      var response = await Http.get(url: "/posts/$id");
  PostModel post = PostModelObjFromJson(json.encode(response.data));
  
  return post;
});



class PostDetailPage extends ConsumerStatefulWidget {
  
  const PostDetailPage({
    Key? key,
  }) : super(key: key);

  

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState {
  FirebaseDatabase database = FirebaseDatabase.instance;
  final _keyForm = GlobalKey<FormState>();

  @override
  void initState() {
    
    super.initState();
  }

 
  @override
  void dispose() {
    super.dispose();
    database.goOffline();
    
  }
  RouteState get _routeState => RouteStateScope.of(context);
  
  @override
  Widget build(BuildContext context) {
     if (FirebaseAuth.instance.currentUser == null) {
      RouteStateScope.of(context).go("/signin");
      return Container();
    }
    var id = _routeState.route.parameters['id'];
    if (id == null) {
    
      return Container();
    }
    var provider = ref.watch(_getDataProvider(id));
    return provider.when(
        loading: () => Center(
              child: CircularProgressIndicator(),
            ),
        error: (dynamic err, stack) {
           if (err.message == 401) {
            FirebaseAuth.instance.signOut();
            RouteStateScope.of(context).go("/signin");
            
          }

          return Text("Error: ${err}");
        },
        data: (data) {
 

          return Scaffold(
            body: Stack(children: [
              Positioned.fill(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(38.0, 0, 38.0, 8.0),
                      child: Container(
                          margin:EdgeInsets.symmetric(vertical: 30.0),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PostCard(data),
                          CommentCard(data),
                          // const _SignUpButton(),
                        ],
                      ))))
            ]),
          );
        });
  }

  Widget PostCard(PostModel post){
    
  return Card(
      clipBehavior: Clip.antiAlias,
      child:  Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.person),
                title: Text(post.createdByName??''),
              ),
              
              ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.question_mark),
                title:Text(post.type??''),
              ),
              ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.pets),
                title: Text(post.petType??''),
                
              ),
              ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.lock_clock),
                title: Text(Helper.getTimeAgo(post.createdOn)),
              ),
              ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.list),
                title: Text(post.breed??''),
              ),
               ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.location_on_rounded),
                title: Text(post.district??''),
              ),
              ListTile(
                minLeadingWidth: 2,
                leading: Icon(Icons.edit),
                title: Text("Description "),
                subtitle: Text(post.about??''),
              ),
              
              Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                child: PhotoView(
                  // customSize: Size(MediaQuery.of(context).size.width,150),
                  imageProvider:
                      NetworkImage(Config.apiServer + "/posts/image/${post.id}"),

                  initialScale: PhotoViewComputedScale.contained,
                ),
              ),
            ],
          )
    );
  
}


   Widget CommentCard(PostModel profile){
  return Form(
       key: _keyForm,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child:  Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              AuthTextField(
                maxLines: 4,
                key: const Key('comment'),
                icon: Icon(Icons.comment),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                hint: 'Comments',                
                keyboardType: TextInputType.multiline,
                validator: (value) => Validations.validateText(value)),
              
              CupertinoButton(
                onPressed: () {
                  if(_keyForm.currentState!.validate()){
                    
                  }
                  // RouteStateScope.of(context).go("/post/${profile.id}");
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    //  A google icon here
                    //  an External Package used here
                    //  Font_awesome_flutter package used
                    Text("Send Private comment"),
                  ],
                )
                //_saveButtons(),
                // Image.asset('assets/card-sample-image.jpg'),
                // Image.asset('assets/card-sample-image-2.jpg'),
              ),
            ],
          ))
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
                onPressed:()=> ref.read(GlobalProvider).logout()));
      },
    );
  }
}