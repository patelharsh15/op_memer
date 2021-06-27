import 'dart:async';

import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ProfilePage.dart';
import 'admob_service.dart';

class FollowersPage extends StatefulWidget {
  final String userProfileId;

  FollowersPage({this.userProfileId});
  @override
  _FollowersPageState createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final scrollController = ScrollController();
  List<UserResult> followersResults;
  DocumentSnapshot startAfter;
  int limit = 9;
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
          findFollowers2();
        }
      }
    });
    findFollowers();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  findFollowers({bool clearCachedData = false}) async {
    if (clearCachedData) {
      setState(() {
        this.followersResults = null;
      });
    }

    QuerySnapshot allFollowers = await followersRefrence
        .doc(widget.userProfileId)
        .collection("userFollowers")
        .limit(limit)
        .get();
    List<UserResult> searchFollowersResult = [];

    allFollowers.docs.forEach((document) async {
      QuerySnapshot ds =
          await usersReference.where("id", isEqualTo: document.id).get();
      ds.docs.forEach((docu) {
        User eachUser = User.fromDocument(docu);
        UserResult userResult = UserResult(eachUser);
        searchFollowersResult.add(userResult);
      });
      count++;
      if (count == allFollowers.docs.length) {
        setState(() {
          this.followersResults = searchFollowersResult;
          count = 0;
        });
      }
    });

    setState(() {
      if (allFollowers != null) {
        if (allFollowers.docs.length != 0) {
          startAfter = allFollowers.docs[allFollowers.docs.length - 1];
        }
      }
    });
  }

  findFollowers2() async {
    SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey,
      content: Container(
        height: 2.0,
        child: linearProgressSnackbar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    QuerySnapshot allFollowers2 = await followersRefrence
        .doc(widget.userProfileId)
        .collection("userFollowers")
        .startAfterDocument(startAfter)
        .limit(limit)
        .get();
    List<UserResult> searchFollowersResult = [];
    if (allFollowers2.docs.length == 0) {
      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text(
          "No more Followers",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (allFollowers2.docs.length != 0) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      allFollowers2.docs.forEach((document) async {
        QuerySnapshot ds2 =
            await usersReference.where("id", isEqualTo: document.id).get();
        ds2.docs.forEach((docu) {
          User eachUser = User.fromDocument(docu);
          UserResult userResult = UserResult(eachUser);
          searchFollowersResult.add(userResult);
        });
        count2++;
        if (count2 == allFollowers2.docs.length) {
          setState(() {
            this.followersResults =
                this.followersResults + searchFollowersResult;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            count2 = 0;
          });
        }
      });

      setState(() {
        if (allFollowers2 != null) {
          if (allFollowers2.docs.length != 0) {
            startAfter = allFollowers2.docs[allFollowers2.docs.length - 1];
          }
        }
      });
    }
  }

  Container displayFollowersScreen() {
    return Container(
      child: RefreshIndicator(
          child: createFollowersNameList(),
          onRefresh: () => findFollowers(
              clearCachedData: true)), // onRefresh: () => retriveName()
    );
  }

  createFollowersNameList() {
    if (followersResults == null) {
      return circularProgress();
    } else if (followersResults.toString() == "[]") {
      return Center(
        child: ListView(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height / 4),
            controller: scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            children: <Widget>[
              Container(
                color: Theme.of(context).accentColor.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "No Followers found",
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
      children: followersResults,
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
        appBar: header(context, strTitle: "Followers"),
        onTap: () {
          scrollController.animateTo(0,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
      //appBar: header(context, strTitle:"Followers"),
      body:
          displayFollowersScreen(), //followersResults == null ? displayNoFollowersScreen() :
      bottomNavigationBar: Container(
        alignment: Alignment.center,
        child: AdWidget(
          ad: AdmobService.createBannerAdSmall()..load(),
        ), //AdmobService.createBannerAd()..load()
        height: 50,
      ),
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
                  radius: 27,
                  backgroundColor: Colors.lightBlueAccent,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: CachedNetworkImageProvider(eachUser.url),
                    radius: 25,
                  ),
                ),
                title: Text(
                  eachUser.profileName,
                  style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontSize: 15.0,
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
