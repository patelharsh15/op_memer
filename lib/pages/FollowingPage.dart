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

class FollowingPage extends StatefulWidget {
  final String userProfileId;

  FollowingPage({this.userProfileId});
  @override
  _FollowingPageState createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  final scrollController =  ScrollController();
  List<UserResult> followingResults;
  DocumentSnapshot startAfter;
  int limit=9;
  int count=0;
  int count2=0;

  @override
  void initState(){
    super.initState();
    findFollowing();
    scrollController.addListener((){
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          findFollowing2();
        }
      }
    });
  }

  @override
  void dispose(){
    super.dispose();
    scrollController.dispose();
  }


  findFollowing({bool clearCachedData = false}) async
  {
    if(clearCachedData) {
      setState(() {
        followingResults = null;
      });
    }
    List<UserResult> searchFollowersResult = [];
    QuerySnapshot allFollowings = await followingRefrence.doc(widget.userProfileId).collection("userFollowing").limit(limit).get();
    allFollowings.docs.forEach((document) async {
      QuerySnapshot ds = await usersReference.where("id", isEqualTo: document.id).get();
      ds.docs.forEach((docu) {
        User eachUser = User.fromDocument(docu);
        UserResult userResult = UserResult(eachUser);
        searchFollowersResult.add(userResult);
      });
      count++;
      if(count == allFollowings.docs.length){
        setState(() {
          this.followingResults = searchFollowersResult;
          count =0;
        });
      }
    });
    if(allFollowings.docs.length == 0)
      {
        setState(() {
          this.followingResults = searchFollowersResult;


        });
      }

    setState(() {
      if(allFollowings!=null)
      {
        if(allFollowings.docs.length != 0)
        {
          startAfter = allFollowings.docs[allFollowings.docs.length-1];
        }
      }
    });
  }

  findFollowing2() async
  {
    SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey,
      content: Container(
        height:2.0,
        child: linearProgressSnackbar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    List<UserResult> searchFollowersResult = [];
    QuerySnapshot allFollowings2 = await followingRefrence.doc(widget.userProfileId).collection("userFollowing")
        .startAfterDocument(startAfter)
        .limit(limit).get();

    if(allFollowings2.docs.length == 0 )
    {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text("No more Followings",textAlign: TextAlign.center, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    else if(allFollowings2.docs.length != 0)
    {
      allFollowings2.docs.forEach((document) async {
        QuerySnapshot ds2 = await usersReference.where("id", isEqualTo: document.id).get();
        ds2.docs.forEach((docu) {
          User eachUser = User.fromDocument(docu);
          UserResult userResult = UserResult(eachUser);
          searchFollowersResult.add(userResult);
        });
        count2++;
        if(count2 == allFollowings2.docs.length)
        {
          setState(() {
            this.followingResults = this.followingResults + searchFollowersResult;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            count2=0;
          });
        }
      });

      setState(() {
        if(allFollowings2!=null)
        {
          if(allFollowings2.docs.length != 0)
          {
            startAfter = allFollowings2.docs[allFollowings2.docs.length-1];
          }
        }
      });
    }
  }


  Container displayFollowersScreen() {
    return Container(
      child: RefreshIndicator(child: createFollowersNameList(),
          onRefresh: () => findFollowing(clearCachedData: true)), // onRefresh: () => retriveName()
    );
  }

  createFollowersNameList(){
    if(followingResults == null){
      return circularProgress();
    }
    else if(followingResults.toString() == "[]")
      {
        return Center(
          child: ListView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height/4),
              controller: scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: <Widget>[Container(
                //color: Theme.of(context).accentColor.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text("Follow your friends to see their Creative Memes",textAlign: TextAlign.center, style: TextStyle(color: Colors.lightBlueAccent, fontSize: 50.0,fontFamily: "Signatra",),),
                  ],
                ),
              ),]
          ),
        );
      }
      return ListView(children: followingResults, controller: scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.black,

      appBar: CustomAppBar(
        appBar: header(context, strTitle:"Followings"),
        onTap: () {
          scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),

      //appBar: header(context, strTitle:"Followings"),
      body: displayFollowersScreen(),//followingResults == null ? displeyNoFollowingScreen() :
      bottomNavigationBar: Container(
        alignment: Alignment.center,
        child: AdWidget(ad: AdmobService.createBannerAdSmall()..load(),),//AdmobService.createBannerAd()..load()
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
              onTap: ()=>  displayUserProfile(context, userProfileId: eachUser.id),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.lightBlueAccent,
                  child: CircleAvatar(backgroundColor: Theme.of(context).cardColor, backgroundImage: CachedNetworkImageProvider(eachUser.url), radius: 25,),
                ),


                title: Text(eachUser.profileName, style: TextStyle(
                  color: Theme.of(context).cardColor, fontSize: 15.0, fontWeight: FontWeight.bold,

                ),//black
                ),
                subtitle: Text(eachUser.username, style: TextStyle(
                  color: Theme.of(context).cardColor, fontSize: 13.0,

                ),),
              ),
            ),
          ],
        ),
      ),
    );
  }
  displayUserProfile(BuildContext context, {String userProfileId})
  {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }
}
