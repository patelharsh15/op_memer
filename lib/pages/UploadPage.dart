import 'dart:io';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as ImD;
import 'package:buddiesgram/pages/image_editor.dart';

class UploadPage extends StatefulWidget {

  final User gCurrentUser;
  UploadPage({this.gCurrentUser});
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> with AutomaticKeepAliveClientMixin<UploadPage> {

  File file;
  User user;
  bool uploading = false;
  String postId = Uuid().v4();
  TextEditingController descriptionTextEditingController = TextEditingController();
  TextEditingController locationTextEditingController = TextEditingController();
  //final _scaffoldKey = GlobalKey<ScaffoldState>();

  captureImageWithCamera() async {
    Navigator.pop(context);
    File imageFile = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 680,
      maxWidth: 970,
    );
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
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
      this.file = croppedFile;
    });
  }


  pickImageFromGallery() async{
    Navigator.pop(context);
    File imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
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
      this.file = croppedFile;
    });
  }

  takeImage(mContext){
    return showDialog(
      context: mContext,
      builder: (context){
        return SimpleDialog(
          title: Text("New Post", style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),),
          children: <Widget>[
            SimpleDialogOption(
              child: Text("Capture Image with camera", style: TextStyle(color: Theme.of(context).cardColor,),),
              onPressed: captureImageWithCamera,
            ),
            SimpleDialogOption(
              child: Text("Select image from gallery", style: TextStyle(color: Theme.of(context).cardColor,),),
              onPressed: pickImageFromGallery,
            ),
            SimpleDialogOption(
              child: Text("Create your Own MEME", style: TextStyle(color: Theme.of(context).cardColor,),),
              onPressed: () {
                Navigator.pop(context);
                getimageditor();

                },

            ),
            SimpleDialogOption(
              child: Text("Cancel", style: TextStyle(color: Theme.of(context).cardColor,),),
              onPressed: ()=> Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  displayUploadScreen(){
    return Container(
      //color: Theme.of(context).accentColor.withOpacity(0.5),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.25,right:MediaQuery.of(context).size.width*0.2,left:MediaQuery.of(context).size.width*0.2 ),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        //mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.add_photo_alternate, color: Theme.of(context).cardColor,size: 200.0,),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.0),),
              child: Text("Upload Image", style: TextStyle(color: Theme.of(context).cardColor, fontSize: 40.0,fontFamily: "Signatra",),),
              color: Colors.lightBlueAccent,
              onPressed: ()=> takeImage(context),
            ),
          ),
        ],
      ),
    );
  }

  clearPostInfo(){

    locationTextEditingController.clear();
    descriptionTextEditingController.clear();

    setState(() {
      file = null;
    });
  }

  getUserCurrentLocation() async {
    Position position= await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placeMarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark mPlaceMark = placeMarks[0];
    //String completeAddressInfo= '${mPlaceMark.subThoroughfare} ${mPlaceMark.thoroughfare}, ${mPlaceMark.subLocality} ${mPlaceMark.locality}, ${mPlaceMark.subAdministrativeArea} ${mPlaceMark.administrativeArea}, ${mPlaceMark.postalCode} ${mPlaceMark.country},';
    String specificAddress = '${mPlaceMark.locality}, ${mPlaceMark.country}';
    locationTextEditingController.text = specificAddress;
  }

  compressingPhoto() async{
    final tDirectory = await getTemporaryDirectory();
    final path = tDirectory.path;
     ImD.Image mImageFile = ImD.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(ImD.encodeJpg(mImageFile, quality:20));
    setState(() {
      file = compressedImageFile;
    });
  }

  controlUploadAndSave() async {
    setState(() {
      uploading = true;
    });
    await compressingPhoto();

    String downloadUrl = await uploadPhoto(file);

    savePostInfoToFireStore(url: downloadUrl, location: locationTextEditingController.text, description: descriptionTextEditingController.text);

    SnackBar snackBar = SnackBar(content: Text("Image Uploaded "));
    //_scaffoldKey.currentState.showSnackBar(snackBar);
    //Scaffold.of(context).showSnackBar(snackBar);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    locationTextEditingController.clear();
    descriptionTextEditingController.clear();



    setState(() {
      file = null;
      uploading=false;
      postId=Uuid().v4();
    });
  }

  savePostInfoToFireStore({String url, String location, String description}) async
  {
    postsReference.doc(widget.gCurrentUser.id).collection("usersPosts").doc(postId).set({
      "postId": postId,
      "ownerId": widget.gCurrentUser.id,
      "emailId": widget.gCurrentUser.email,
      "timestamp": DateTime.now(),
      "countLike" : 0,
      //"likes":{},
      //"likesCount" : 0,
      "username": widget.gCurrentUser.username,
      "description": description,
      "location": location,
      "url": url,
    });
    commentsRefrence.doc(postId).set({"postId": postId, "ownerId": widget.gCurrentUser.id,
      "emailId": widget.gCurrentUser.email,});

  }

  Future<String> uploadPhoto(mImageFile) async{

    //String username = widget.gCurrentUser.username;
    String time = DateTime.now().toString();
    UploadTask mStorageUploadTask = storageReference.child(widget.gCurrentUser.id).child("$time"+"_""$postId").putFile(mImageFile); //StorageUploadTask
    //TaskSnapshot storageTaskSnapshot = await mStorageUploadTask.onComplete; //StorageTastSnapshot
    String downloadUrl= await (await mStorageUploadTask).ref.getDownloadURL();
    //String downloadUrl= await storageTaskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }


  displayUploadFormScreen(){
    return Scaffold(
      //key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        brightness: Brightness.dark,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).cardColor,), onPressed: clearPostInfo),
        title: Text("New Post", style: TextStyle(fontSize: 24.0, color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),),
        actions: <Widget>[
          TextButton(
            onPressed: uploading ? null : controlUploadAndSave,
            child: Text("Share", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 16.0),),

          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          uploading ? linearProgress() : Text(""),
          Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width * 1,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(image: DecorationImage(image: FileImage(file),fit: BoxFit.contain,)),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 12.0),),
          ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.lightBlueAccent,
              child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(widget.gCurrentUser.url),),
            ),

            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Theme.of(context).cardColor),
                controller: descriptionTextEditingController,
                decoration: InputDecoration(
                  hintText: "Say something about your image.",
                  hintStyle: TextStyle(color: Theme.of(context).cardColor),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.person_pin_circle, color: Theme.of(context).cardColor, size: 36.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                style: TextStyle(color: Theme.of(context).cardColor),
                controller: locationTextEditingController,
                decoration: InputDecoration(
                  hintText: "Write the location here.",
                  hintStyle: TextStyle(color: Theme.of(context).cardColor),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 220.0,
            height: 110.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35.0)),
              color: Colors.green,
              icon: Icon(Icons.location_on, color: Theme.of(context).cardColor,),
              label: Text("Get My location.",style: TextStyle(color: Theme.of(context).cardColor),),
              onPressed: getUserCurrentLocation,
            ),
          )
        ],
      ),
    );
  }

  Future<void> getimageditor()  {
    final geteditimage =   Navigator.push(context, MaterialPageRoute(
        builder: (context){
          return ImageEditorPro(
            appBarColor: Colors.blue,
            bottomBarColor: Colors.blue,
          );
        }
    )).then((geteditimage){
      if(geteditimage != null){
        setState(() {
          file =  geteditimage;
        });
      }
    }).catchError((er){print(er);});


  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return file == null ? displayUploadScreen() : displayUploadFormScreen();
  }
}


