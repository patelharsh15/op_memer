import 'dart:async';
import 'dart:io';
import 'package:buddiesgram/models/user.dart' as u;
import 'package:buddiesgram/pages/CreateAccountPage.dart';
import 'package:buddiesgram/pages/NotificationsPage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/pages/SearchPage.dart';
import 'package:buddiesgram/pages/TimeLinePage.dart';
import 'package:buddiesgram/pages/UploadPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final googleSignIn = GoogleSignIn();
final usersReference = FirebaseFirestore.instance.collection("users");
final Reference storageReference =
    FirebaseStorage.instance.ref().child("Posts Pictures");
final Reference storageReferenceP =
    FirebaseStorage.instance.ref().child("Profile Pictures");
final postsReference = FirebaseFirestore.instance.collection("posts");
final activityFeedReference = FirebaseFirestore.instance.collection("feed");
final commentsRefrence = FirebaseFirestore.instance.collection("comments");
final followersRefrence = FirebaseFirestore.instance.collection("followers");
final followingRefrence = FirebaseFirestore.instance.collection("following");
final timelineRefrence = FirebaseFirestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
u.User currentUser;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSignedIn = false;
  bool firstPage = true;
  PageController pageController;
  int getPageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void initState() {
    super.initState();

    pageController = PageController();

    gSignIn.onCurrentUserChanged.listen((gSigninAccount) {
      controlSignIn(gSigninAccount);
    }, onError: (gError) {
      Timer(Duration(seconds: 3), () {
        setState(() {
          firstPage = false;
        });
      });

      SnackBar snackBar = SnackBar(
        backgroundColor: Colors.grey,
        content: Text(
          "first" + gError.toString(),
          style: TextStyle(color: Colors.black),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print("first - Error Message: " + gError.toString());
    });

    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount) {
      controlSignIn(gSignInAccount);
    }).catchError((gError) {
      Timer(Duration(seconds: 3), () {
        setState(() {
          firstPage = false;
        });
      });

      SnackBar snackBar = SnackBar(
        backgroundColor: Colors.grey,
        content: Text(
          "silent" + gError.toString(),
          style: TextStyle(color: Colors.black),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print("silent - Error Message: " + gError.toString()); // + gerror
    });
  }

  controlSignIn(GoogleSignInAccount signInAccount) async {
    if (signInAccount != null) {
      // final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
      // DocumentSnapshot documentSnapshot = await usersReference.doc(gCurrentUser.id).get();
      // currentUser = User.fromDocument(documentSnapshot);
      // setState(() {
      //   firstPage=false;
      // });

      await saveUserInfoToFireStore();
      setState(() {
        isSignedIn = true;
      });

      configureRealTimePushNotifications();
    } else {
      setState(() {
        isSignedIn = false;
      });
    }
  }

  configureRealTimePushNotifications() {
    final GoogleSignInAccount gUser = gSignIn.currentUser;

    if (Platform.isIOS) {
      getIOSPermissions();
    }

    _firebaseMessaging.getToken().then((token) {
      usersReference.doc(gUser.id).update({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> msg) async {
        final String recipientId = msg["data"]["recipient"];
        final String body = msg["notification"]["body"];

        if (recipientId == gUser.id) {
          SnackBar snackBar = SnackBar(
            backgroundColor: Colors.grey,
            content: Text(
              body,
              style: TextStyle(color: Colors.black),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          // _scaffoldKey.currentState.showSnackBar(snackBar);
        }
      },
    );
  }

  getIOSPermissions() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));

    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings Registered :  $settings");
    });
  }

  saveUserInfoToFireStore() async {
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot =
        await usersReference.doc(gCurrentUser.id).get();

    if (!documentSnapshot.exists) {
      var username = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => CreateAccountPage()));

      String searchName =
          gCurrentUser.displayName.toLowerCase().replaceAll(' ', '');

      usersReference.doc(gCurrentUser.id).set({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "username": username,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "",
        "timestamp": timestamp,
        "searchName": searchName,
      });
      if (username == null) {
        usersReference.doc(gCurrentUser.id).delete();
        gSignIn.signOut();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      } else if (username != null) {
        FirebaseFirestore.instance.collection("username").doc(username).set({
          "username": username,
          "id": gCurrentUser.id,
          "email": gCurrentUser.email,
        });
      }
      await followingRefrence.doc(gCurrentUser.id).set({
        "countFollowings": 0,
        "email": gCurrentUser.email,
        "userId": gCurrentUser.id,
      });
      await followersRefrence.doc(gCurrentUser.id).set({
        "countFollowers": 0,
        "email": gCurrentUser.email,
        "userId": gCurrentUser.id,
      });
      await followersRefrence
          .doc(gCurrentUser.id)
          .collection("userFollowers")
          .doc(gCurrentUser.id)
          .set({
        "userId": gCurrentUser.id,
      });
      await postsReference.doc(gCurrentUser.id).set({
        "countPosts": 0,
        "profileName": gCurrentUser.displayName,
        "email": gCurrentUser.email,
        "id": gCurrentUser.id,
        "username": username,
      });
      await activityFeedReference.doc(gCurrentUser.id).set({
        "id": gCurrentUser.id,
        "email": gCurrentUser.email,
      });
      await timelineRefrence.doc(gCurrentUser.id).set({
        "id": gCurrentUser.id,
        "email": gCurrentUser.email,
      });

      documentSnapshot = await usersReference.doc(gCurrentUser.id).get();
      if (documentSnapshot.exists) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      }

      //Navigator.pop(context);
      //Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    }
    currentUser = u.User.fromDocument(documentSnapshot);
    setState(() {
      isSignedIn = true;
      firstPage = false;
    });
  }

  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  loginUser() async {
    try {
      final googleUser = await gSignIn.signIn();
      final googleAuth = await googleUser.authentication;
      final credentials = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credentials);
    } catch (e) {
      SnackBar snackBar = SnackBar(
        backgroundColor: Colors.grey,
        content: Text(
          "loginUser" + e.toString(),
          style: TextStyle(color: Colors.black),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print(e.toString());
    }
  }

  logoutUser() async {
    await gSignIn.signOut();
    FirebaseAuth.instance.signOut();
  }

  onTapChangePage(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    //pageController.jumpToPage(pageIndex);
  }

  whenPageChanges(int pageIndex) {
    setState(() {
      this.getPageIndex = pageIndex;
    });
  }

  Scaffold buildHomeScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          TimeLinePage(
            gCurrentUser: currentUser,
          ),
          //RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close),label: Text("Sign Out")),
          SearchPage(),
          UploadPage(
            gCurrentUser: currentUser,
          ),
          NotificationsPage(),
          ProfilePage(userProfileId: currentUser.id),
        ],
        controller: pageController,
        onPageChanged: whenPageChanges,
        physics: NeverScrollableScrollPhysics(),
        //physics: BouncingScrollPhysics(),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        items: <Widget>[
          Icon(
            Icons.home_rounded,
            color: Colors.white,
          ),
          Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
          ),
          Icon(
            Icons.library_add_rounded,
            color: Colors.white,
          ),
          Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
          ),
          Icon(
            Icons.person,
            color: Colors.white,
          ),
        ],
        height: 50,
        color: Colors.lightBlueAccent,
        buttonBackgroundColor: Colors.orange,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 400),
        onTap: onTapChangePage,
      ),
    );
    //return RaisedButton.icon(onPressed: logoutUser, icon: Icon(Icons.close),label: Text("Sign Out"));
  }

  Scaffold buildSignInScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            //colors: [Theme.of(context).accentColor, Theme.of(context).primaryColor],
            //colors: [Colors.lightBlueAccent, Colors.white],
            colors: [Colors.teal, Colors.purple],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "op Memer",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 90.0,
                color: Colors.white,
                fontFamily: "Signatra",
              ),
            ),
            GestureDetector(
              onTap: loginUser,
              child: Container(
                width: 270.0,
                height: 65.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/google_signin_button.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Scaffold firstBuildPage() {
    return Scaffold(
      body: Container(
        //width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            //colors: [Theme.of(context).accentColor, Theme.of(context).primaryColor],
            //colors: [Colors.lightBlueAccent, Colors.white],
            colors: [Colors.teal, Colors.purple],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "One who controls the Memes, contols the Universe.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40.0,
                color: Colors.black,
                fontFamily: "Signatra",
              ),
            ),
            Text(
              "- Elon Musk",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 50.0,
                color: Colors.white,
                fontFamily: "Signatra",
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //saveUserInfoToFireStore();
    if (firstPage == true) {
      return firstBuildPage();
    } else if (isSignedIn && firstPage == false) {
      return buildHomeScreen(); //buildHomeScreen
    } else {
      return buildSignInScreen(); //buildSignInScreen
    }
  }
}
