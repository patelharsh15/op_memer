import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'ProfilePage.dart';

class LikePage extends StatefulWidget {
  final String ownerId;
  final String postId;
  LikePage({this.ownerId, this.postId});

  @override
  _LikePageState createState() =>
      _LikePageState(ownerId: ownerId, postId: postId);
}

class _LikePageState extends State<LikePage> {
  final String ownerId;
  final String postId;
  _LikePageState({this.ownerId, this.postId});
  final scrollController = ScrollController();
  List<UserResult> LikesResults;
  DocumentSnapshot startAfter;
  int limit = 9;
  int limit2 = 9;
  bool onceAgain = true;
  int count = 0;
  int count2 = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          findLikes2();
        }
      }
    });
    findLikes();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  findLikes({bool clearCachedData = false}) async {
    if (clearCachedData) {
      setState(() {
        this.LikesResults = null;
      });
    }
    //print(likes.keys);
    QuerySnapshot allLikes = await postsReference
        .doc(ownerId)
        .collection("usersPosts")
        .doc(postId)
        .collection("like")
        .limit(limit)
        .get();
    List<UserResult> searchLikesResult = [];
    allLikes.docs.forEach((document) async {
      QuerySnapshot ds =
          await usersReference.where("id", isEqualTo: document.id).get();
      ds.docs.forEach((docu) {
        User eachUser = User.fromDocument(docu);
        UserResult userResult = UserResult(eachUser);
        searchLikesResult.add(userResult);
      });
      count++;
      if (count == allLikes.docs.length) {
        setState(() {
          this.LikesResults = searchLikesResult;
          count = 0;
        });
      }
    });
    if (allLikes.docs.length == 0) {
      setState(() {
        this.LikesResults = searchLikesResult;
      });
    }
    setState(() {
      if (allLikes != null) {
        if (allLikes.docs.length != 0) {
          startAfter = allLikes.docs[allLikes.docs.length - 1];
        }
      }
    });
  }

  findLikes2() async {
    SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey,
      content: Container(
        height: 2.0,
        child: linearProgressSnackbar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    QuerySnapshot allLikes2 = await postsReference
        .doc(ownerId)
        .collection("usersPosts")
        .doc(postId)
        .collection("like")
        .startAfterDocument(startAfter)
        .limit(limit2)
        .get();
    List<UserResult> searchLikesResult = [];
    if (allLikes2.docs.length == 0) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text(
          "No more Likes",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (allLikes2.docs.length != 0) {
      allLikes2.docs.forEach((document) async {
        QuerySnapshot ds2 =
            await usersReference.where("id", isEqualTo: document.id).get();
        ds2.docs.forEach((docu) {
          User eachUser = User.fromDocument(docu);
          UserResult userResult = UserResult(eachUser);
          searchLikesResult.add(userResult);
        });
        count2++;
        if (count2 == allLikes2.docs.length) {
          setState(() {
            this.LikesResults = this.LikesResults + searchLikesResult;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            count2 = 0;
          });
        }
      });

      setState(() {
        if (allLikes2 != null) {
          if (allLikes2.docs.length != 0) {
            startAfter = allLikes2.docs[allLikes2.docs.length - 1];
          }
        }
      });
    }
  }

  displayLikesScreen() {
    return Container(
      child: RefreshIndicator(
          child: createLikesNameList(),
          onRefresh: () => findLikes(
              clearCachedData: true)), // onRefresh: () => retriveName()
    );
  }

  createLikesNameList() {
    if (LikesResults == null) {
      return circularProgress();
    } else if (LikesResults.toString() == "[]") {
      return Center(
        child: ListView(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height / 4),
            controller: scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            children: <Widget>[
              Container(
                //color: Theme.of(context).accentColor.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "No Likes",
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 50.0,
                        fontFamily: "Signatra",
                      ),
                    ),
                  ],
                ),
              ),
            ]),
      );
    }

    return ListView(
      children: LikesResults,
      controller: scrollController,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.black,

      appBar: CustomAppBar(
        appBar: header(context, strTitle: "Likes"),
        onTap: () {
          scrollController.animateTo(0,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),

      //appBar: header(context, strTitle:"Likes"),
      body:
          displayLikesScreen(), //followersResults == null ? displayNoFollowersScreen() :
    );
  }
}

class UserResult extends StatelessWidget {
  final User eachUser;
  UserResult(this.eachUser);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3.0),
      child: Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(20),
        //   color: Colors.blueGrey,
        // ),

        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: () =>
                  displayUserProfile(context, userProfileId: eachUser.id),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.lightBlueAccent,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: CachedNetworkImageProvider(eachUser.url),
                  ),
                ),
                title: Text(
                  eachUser.profileName,
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  eachUser.username,
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  displayUserProfile(BuildContext context, {String userProfileId}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }
}
