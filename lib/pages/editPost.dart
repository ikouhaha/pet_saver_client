import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:pet_saver_client/common/config.dart';
import 'package:pet_saver_client/common/helper.dart';
import 'package:pet_saver_client/common/http-common.dart';
import 'package:pet_saver_client/common/image_field.dart';
import 'package:pet_saver_client/common/sharePerfenceService.dart';
import 'package:pet_saver_client/common/validations.dart';
import 'package:pet_saver_client/components/auth_dropdown_field.dart';
import 'package:pet_saver_client/components/auth_radio_field.dart';
import 'package:pet_saver_client/components/auth_text_field.dart';
import 'package:pet_saver_client/models/Breed.dart';
import 'package:pet_saver_client/models/formController.dart';
import 'package:pet_saver_client/models/options.dart';
import 'package:pet_saver_client/models/post.dart';
import 'package:pet_saver_client/models/petDetect.dart';
import 'package:pet_saver_client/providers/global_provider.dart';
import 'package:pet_saver_client/router/route_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostLoadingData {
  final List<Option> catBreeds;
  final List<Option> dogBreeds;
  final List<Option> districts;
  final PostModel post;

  PostLoadingData(this.catBreeds, this.dogBreeds, this.districts, this.post);
}

final _getDataProvider =
    FutureProvider.autoDispose.family<PostLoadingData, int>((ref, id) async {
  var response = await Http.get(url: "/options/breeds/cat");
  var catBreeds = optionsFromJson(json.encode(response.data));
  response = await Http.get(url: "/options/breeds/dog");
  var dogBreeds = optionsFromJson(json.encode(response.data));
  response = await Http.get(url: "/options/districts");
  var districts = optionsFromJson(json.encode(response.data));
  response = await Http.get(url: "/posts/$id");
  var post = PostModelObjFromJson(json.encode(response.data));
  return PostLoadingData(catBreeds, dogBreeds, districts, post);
});

class EditPostPage extends ConsumerStatefulWidget {
  User? user;
  String? pid;
  EditPostPage({
    Key? key,
    this.user,
    this.pid
  }) : super(key: key);

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<EditPostPage> {
  PostModel post = PostModel();
  final _keyForm = GlobalKey<FormState>();
  final _petType = FormController();
  final _postType = FormController();
  final _breeds = FormController();
  final _about = FormController();
  final _district = FormController();
  bool isInit = false;
  int id = -1;

  List<Option> dogBreeds = [];
  List<Option> catBreeds = [];
  List<Option> postTypes = [];
  List<Option> districts = [];
  List<PetDetectResponse> results = [];
  @override
  void initState() {
    super.initState();
    //_petType.ct.text = "cat"; //default value
    var profile = SharedPreferencesService.getProfile()!;
    post.createdBy = profile.id;

    _district.ct.addListener(() {
      if (_district.ct.text.isNotEmpty) {
        int? value = int?.parse(_district.ct.text);
        post.districtId = value;
      }
    });
    _petType.ct.addListener(() {
      post.petType = _petType.ct.text;
    });

    _breeds.ct.addListener(() {
      if (_breeds.ct.text.isNotEmpty) {
        int? value = int?.parse(_breeds.ct.text);
        post.breedID = value;
      }
    });

    _postType.ct.addListener(() {
      post.type = _postType.ct.text;
    });

    _about.ct.addListener(() {
      post.about = _about.ct.text;
    });

    if (profile.role == "user") {
      postTypes.add(Option(value: "lost", name: "Lost"));
      postTypes.add(Option(value: "found", name: "Found"));
    } else if (profile.role == "staff") {
      postTypes.add(Option(value: "lost", name: "Lost"));
      postTypes.add(Option(value: "found", name: "Found"));
      postTypes.add(Option(value: "adopt", name: "Adoption"));
    }
  }

  @override
  void dispose() {
    super.dispose();
    _keyForm.currentState?.dispose();
    _breeds.dispose();
    _postType.dispose();
    _petType.dispose();
    _about.dispose();
    _district.dispose();
  }

  // void _handleBookTapped(Book book) {
  //   _routeState.go('/book/${book.id}');
  // }
  User? get user => widget.user??FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      RouteStateScope.of(context).go("/signin");
      return Scaffold(
          appBar: AppBar(
        title: const Text("Edit Post"),
      ));
    }
    dogBreeds = [];
    catBreeds = [];
    var paramId = widget.pid??RouteStateScope.of(context).route.parameters['id'];
    if (paramId == null) {
      return Scaffold(
          appBar: AppBar(
        title: const Text("Edit Post"),
      ));
    }

    id = int.parse(paramId);
    var provider = ref.watch(_getDataProvider(id));
    //return const Center(child: Text("asdsd"));
    return Scaffold(
        appBar: AppBar(
          title: const Text("Edit Post"),
        ),
        body: provider.when(
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
              dogBreeds = data.dogBreeds;
              catBreeds = data.catBreeds;
              districts = data.districts;

              if (!isInit) {
                post = data.post;
                _district.ct.text = post.districtId.toString();
                _petType.ct.text = post.petType ?? "";
                _postType.ct.text = post.type ?? "";
                _about.ct.text = post.about ?? "";
                _breeds.ct.text =
                    post.breedID == null ? "" : post.breedID.toString();
                isInit = true;
              }

              return Stack(children: [
                Positioned.fill(
                    child: Card(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(1, 0, 1, 8.0),
                            child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 30.0),
                                child: Form(
                                    key: _keyForm,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        //_petTypeField(),

                                        _postTypeField(),
                                        _BreedsField(),
                                        _imageField(),
                                        _districtField(),
                                        _descriptionField(),
                                        _submitButton(),
                                        // const _SignUpButton(),
                                      ],
                                    ))))))
              ]);
            }));
  }

  Widget _imageField() {
    return ImageField(
        image: post.imageBase64 == null
            ? null
            : Helper.getImageByBase64orHttp(post.imageBase64!),
        validator: (value) {
          return Validations.validateText(post.imageBase64);
        },
        callback: (file, setImg) async {
          try {
            EasyLoading.showProgress(0.3, status: 'detecting...');
            Response response = await Http.postImage(
                server: Config.pythonApiServer,
                url: "/detectBase64/0",
                imageFile: file);
            post.imageBase64 = await Helper.imageToBase64(file);
            post.imageFilename = Helper.uuid() + ".jpg";
            results =
                petDetectResponseFromJson(json.encode(response.data["result"]));
            print(results);
            for (var result in results) {
              if (result.name != null) {
                if (result.name != post.petType) {
                  _breeds.ct.text = "";
                }
                _petType.ct.text = result.name!;
                post.petType = result.name!;
                for (var crop in result.cropImgs!) {
                  post.cropImageBase64 = crop;
                }
              }
            }
            //todo make it to multiple, currently just support a pet a image
            if (results.isNotEmpty) {
              setState(() {
                Image img = Helper.getImageByBase64orHttp(results[0].labelImg!);
                setImg(img);
              });
            }
          } catch (e) {
            print(e);
          } finally {
            EasyLoading.dismiss();
          }

          //ref.read(RegisterProvider).setImage(value)
        });
  }

  Widget _districtField() {
    return AuthDropDownField(
        value: _district.ct.text,
        key: const Key('_districtField'),
        icon: const Icon(Icons.map),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        hint: 'District',
        validator: (value) => Validations.validateText(value),
        options: districts,
        onChanged: (value) {
          setState(() {
            _district.ct.text = value;
          });
        });
  }

  Widget _postTypeField() {
    return AuthDropDownField(
        value: _postType.ct.text,
        key: const Key('post type'),
        icon: const Icon(Icons.question_mark),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        hint: 'Post Type',
        validator: (value) => Validations.validateText(value),
        options: postTypes,
        onChanged: (value) {
          setState(() {
            _postType.ct.text = value;
          });
        });
  }

  Widget _petTypeField() {
    return AuthRadioField(
        type: RadioWidget.row,
        key: const Key('pet type'),
        controller: _petType.ct,
        icon: const Icon(Icons.list),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        hint: 'Post Type',
        //validator: (value) => Validations.validateName(value),
        options: [
          Option(name: "cat", value: "cat"),
          Option(name: "dog", value: "dog")
        ],
        onChanged: (value) => setState(() {
              _petType.ct.text = value;
            }));
  }

  Widget _BreedsField() {
    String? value = _breeds.ct.text.isEmpty ? null : _breeds.ct.text;
    if (_petType.ct.text == "cat") {
      return AuthDropDownField(
          key: const Key('breedsCat'),
          icon: const Icon(Icons.list),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          hint: 'Breeds',
          validator: (value) => Validations.validateText(value),
          options: catBreeds,
          value: value,
          onChanged: (value) {
            setState(() {
              _breeds.ct.text = value;
            });
          });
    } else if (_petType.ct.text == "dog") {
      return AuthDropDownField(
        key: const Key('breedsDog'),
        icon: const Icon(Icons.list),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        hint: 'Breeds',
        validator: (value) => Validations.validateText(value),
        options: dogBreeds,
        value: value,
        onChanged: (value) {
          setState(() {
            _breeds.ct.text = value;
          });
        },
      );
    } else {
      return AuthDropDownField(
        key: const Key('breedsEmpty'),
        icon: const Icon(Icons.list),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        hint: 'Please upload a image',
        validator: (value) => Validations.validateText(value),
        options: [],
        value: value,
        onChanged: null,
      );
    }
  }

  Widget _descriptionField() {
    return AuthTextField(
        maxLines: 6,
        controller: _about.ct,
        key: const Key('description'),
        icon: const Icon(Icons.comment),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        hint: 'Description',
        keyboardType: TextInputType.multiline,
        validator: (value) => Validations.validateText(value));
  }

  Widget _submitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: ElevatedButton(
        onPressed: () async {
          // Validate returns true if the form is valid, or false otherwise.
          if (_keyForm.currentState!.validate()) {
            // If the form is valid, display a snackbar. In the real world,
            // you'd often call a server or save the information in a database.
            try {
              EasyLoading.showProgress(0.3, status: 'Processing...');
              Response response =
                  await Http.put(url: "/posts/$id", data: post.toJson());
              //save image after success save the post to the database
              await Http.post(
                  server: Config.pythonApiServer,
                  url: "/image",
                  data: {
                    "name": post.imageFilename,
                    "type": post.petType,
                    "imageBase64": post.imageBase64
                  });
              RouteStateScope.of(context).go("/mypost");
              EasyLoading.showSuccess("create success");
            } catch (e) {
              print(e);
            } finally {
              EasyLoading.dismiss();
            }
          }
        },
        child: const Text('Submit'),
      ),
    );
  }
}


