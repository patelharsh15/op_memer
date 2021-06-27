import 'dart:io';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/admob_service.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as ImD;
import 'package:image_cropper/image_cropper.dart';

class EditProfilePage extends StatefulWidget {
  final String currentOnlineUserId;
  EditProfilePage({
    this.currentOnlineUserId
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  TextEditingController profileNameTextEditingController = TextEditingController();
  TextEditingController bioTextEditingController = TextEditingController();
  final _scaffoldGlobalKey = GlobalKey<ScaffoldState>();
  bool loading = false;
  User user;
  bool _bioValid = true;
  bool _profileNameValid = true;
  File _image;

  void initState(){
    super.initState();
    getAndDisplayUserInformation();
  }

  getAndDisplayUserInformation() async{
    setState(() {
      loading = true;
    });
    DocumentSnapshot documentSnapshot = await usersReference.doc(widget.currentOnlineUserId).get();
    user = User.fromDocument(documentSnapshot);
    profileNameTextEditingController.text = user.profileName;
    bioTextEditingController.text = user.bio;
    setState(() {
      loading = false;
    });
  }

  updateUserData(){
    setState(() {
      profileNameTextEditingController.text.trim().length>15|| profileNameTextEditingController.text.isEmpty ? _profileNameValid=false : _profileNameValid=true;
      bioTextEditingController.text.trim().length>110 ? _bioValid=false : _bioValid = true;
    });

    if(_image != null)
      {
        uploadPic(context);
        SnackBar successSnackBar = SnackBar(content: Text("Profile has be updated successfully."));
        ScaffoldMessenger.of(context).showSnackBar(successSnackBar);
      }

    if(_bioValid && _profileNameValid){
      usersReference.doc(widget.currentOnlineUserId).update({
        "profileName":profileNameTextEditingController.text,
        "bio": bioTextEditingController.text,
        "searchName":profileNameTextEditingController.text.replaceAll(' ', '').toLowerCase(),
      });
      final snackBar = SnackBar(content: Text('Profile Updated'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
   }
  Future uploadPic(BuildContext context)async{
    await compressingPhoto();
    String username = user.username;
    String time = DateTime.now().toString();
    UploadTask uploadTask = storageReferenceP.child("profilePic_$username").child("profilePic_$time,jpg").putFile(_image);  //StorageUploadTask
    String downloadUrl= await (await uploadTask).ref.getDownloadURL();
    usersReference.doc(user.id).update({"url" : downloadUrl});

    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile Picture Uploaded')));
    });
  }
  compressingPhoto() async{
    //String username = user.username;
    final tDirectory = await getTemporaryDirectory();
    final path = tDirectory.path;
    ImD.Image mImageFile = ImD.decodeImage(_image.readAsBytesSync());
    final compressedImageFile = File('$path/img.jpg')..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality:10));
    setState(() {
      _image = compressedImageFile;
    });
  }


  @override
  Widget build(BuildContext context) {
    Future getImage() async{
      File image = await ImagePicker.pickImage(source:ImageSource.gallery);
      File croppedFile = await ImageCropper.cropImage(
          sourcePath: image.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
          androidUiSettings: AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.lightBlueAccent,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          iosUiSettings: IOSUiSettings(
            minimumAspectRatio: 1.0,
          )
      );

      setState(() {
        _image = croppedFile;

      });
    }

    return Scaffold(
      key: _scaffoldGlobalKey,
      appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          iconTheme: IconThemeData(color: Theme.of(context).cardColor),
          title: Text("Edit Profile", style: TextStyle(color: Theme.of(context).cardColor),),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.done, color: Theme.of(context).cardColor, size: 30.0,), onPressed:()=> Navigator.pop(context))

        ],
      ),
      body: loading?circularProgress():ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(padding: EdgeInsets.only(top: 15.0,bottom: 7.0),
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width*0.2 + 3,
                      backgroundColor: Colors.lightBlueAccent,
                      child:
                      CircleAvatar(
                        radius: MediaQuery.of(context).size.width*0.2,
                        child: ClipOval(
                          child: SizedBox(
                            width: 180.0,
                            height: 180.0,
                            child: (_image!=null)?Image.file(_image,fit: BoxFit.contain)
                                : Image.network(user.url,fit: BoxFit.contain),
                          ),
                        ),

                      ),
                    ),

                    ),
                    Padding(padding: EdgeInsets.only(top: 60.0), //change profile image
                    child: IconButton(
                      icon: Icon(
                        Icons.camera_alt_rounded,
                        size: 30.0,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: ()=>{
                        getImage(),
                    },
                    ),
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.all(16.0),
                child: Column(children: <Widget>[
                  createProfileNameTextField(),createBioTextFormField(),
                ],
                ),
                ),
                Padding(padding: EdgeInsets.only(top: 29.0, left: 50.0,right: 50.0),

                  child: ElevatedButton(
                    onPressed: updateUserData,
                    child: Text(
                      "Update",
                      style: TextStyle(color: Colors.black, fontSize: 16.0),
                    ),
                  ),

                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0, left: 50.0,right: 50.0),
                  child: RaisedButton(
                    color: Colors.red,
                    onPressed: logoutUser,
                    child: Text(
                      "Logout",
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                    ),
                  ),

                ),
                Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child:Container(
                    alignment: Alignment.center,
                    child: AdWidget(key: UniqueKey(), ad: AdmobService.createBannerAd()..load(),),//AdmobService.createBannerAd()..load()
                    height: 100,
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child:Container(
                      alignment: Alignment.center,
                      child: AdWidget(key: UniqueKey(), ad: AdmobService.createBannerAd()..load(),),//AdmobService.createBannerAd()..load()
                      height: 100,
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  logoutUser()async{
    gSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context)=>HomePage()));
  }

  Column createProfileNameTextField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(top:13.0),
        child: Text(
          "Profile Name", style: TextStyle(color: Theme.of(context).cardColor.withOpacity(0.7)),
        ),
        ),
        TextField(
          style: TextStyle(color: Theme.of(context).cardColor),
          controller: profileNameTextEditingController,
          decoration: InputDecoration(
            hintText: "Write profile name here..",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).cardColor.withOpacity(0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).cardColor),

            ),
            hintStyle: TextStyle(color: Theme.of(context).cardColor.withOpacity(0.7)),
            errorText: _profileNameValid ? null : "Profile name is very short",
          ),
        ),
      ],
    );
  }

  Column createBioTextFormField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.only(top:13.0),
          child: Text(
            "Bio", style: TextStyle(color: Theme.of(context).cardColor.withOpacity(0.7)),
          ),
        ),
        TextField(
          style: TextStyle(color: Theme.of(context).cardColor),
          controller: bioTextEditingController,
          decoration: InputDecoration(
            hintText: "Write Bio here..",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).cardColor.withOpacity(0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).cardColor),

            ),
            hintStyle: TextStyle(color: Theme.of(context).cardColor.withOpacity(0.7)),
            errorText: _bioValid ? null : "Bio is to long.",
          ),
        ),
      ],
    );
  }
}
