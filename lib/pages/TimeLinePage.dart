import 'dart:ui';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/admob_service.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class TimeLinePage extends StatefulWidget
{
  final User gCurrentUser;

  TimeLinePage({this.gCurrentUser});

  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> with AutomaticKeepAliveClientMixin<TimeLinePage>
{
  //List<Post> posts;
  List<Object> posts;
  //List<Post> lastPost;
  //int count = 0;
  //List<String> followingsList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final scrollController = ScrollController();
  DocumentSnapshot startAfter;
  bool next = true;
  int limit = 5;

  @override
  void initState() {
    super.initState();
    scrollController.addListener((){
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          retrieveTimeLine2();
        }
      }
      // if(scrollController.offset >= scrollController.position.maxScrollExtent)
      //   {
      //       retrieveTimeLine2();
      //   }
    });
    retrieveTimeLine();

    //retrieveFollowings();
  }
  @override
  void dispose(){
    super.dispose();
    scrollController.dispose();
  }


  retrieveTimeLine({bool clearCachedData = false}) async
  {
    if(clearCachedData)
      {
        setState(() {
          this.posts = null;
          //count=1;
        });
      }

    QuerySnapshot querySnapshot = await timelineRefrence.doc(widget.gCurrentUser.id)
        .collection("timelinePosts").orderBy("timestamp", descending: true).limit(limit).get();
    List<Post> allPosts = [];
    if(querySnapshot.docs.length == 0)
      {
        setState(() {
          this.posts = allPosts;
        });
      }
    else {
      for (int i = 0; i <= querySnapshot.docs.length - 1; i = i + 1) {
        DocumentSnapshot ds2 = await postsReference
            .doc(querySnapshot.docs[i]["ownerId"])
            .collection("usersPosts")
            .doc(querySnapshot.docs[i]["postId"])
            .get();
        if (ds2.exists) {
          allPosts.add(Post.fromDocument(ds2));
        }
        if (i == querySnapshot.docs.length - 1) {
          setState(() {
            this.posts = List.from(allPosts);
            if (posts.length >= 3) {
              this.posts.insert(posts.length - 1, AdmobService.createBannerAd()
                ..load());
            }
          });
        }
      }
    }


    // querySnapshot.docs.forEach((element) async {
    //   DocumentSnapshot ds2 = await postsReference.doc(element["ownerId"]).collection("usersPosts").doc(element["postId"]).get();
    //   allPosts.add(Post.fromDocument(ds2));
    //   count++;
    //   if(count == querySnapshot.docs.length)
    //     {
    //       setState(() {
    //         posts = List.from(allPosts);
    //         if(posts.length>=3)
    //         {
    //           posts.insert(posts.length-1,AdmobService.createBannerAd()..load());
    //         }
    //         count=0;
    //       });
    //     }
    //
    // });

    //List<Post> allPosts = querySnapshot.docs.map((document) => Post.fromDocument(document)).toList();

    setState(() {
      if(querySnapshot!=null)
      {
        if(querySnapshot.docs.length != 0)
        {
          startAfter = querySnapshot.docs[querySnapshot.docs.length-1];
        }
      }
      // var ad = AdmobService.createBannerAd();
      // ad.load();
      //this.posts = allPosts;
      //posts = List.from(allPosts);
      // if(posts.length>=3)
      //   {
      //     posts.insert(posts.length-1,AdmobService.createBannerAd()..load());
      //   }

      // for(int i = 4*count ; i <= posts.length;i = i+4)
      //   {
      //     posts.insert(i,AdmobService.createBannerAd()..load());
      //   }
      //count++;

    });
  }

  // retrieveFollowings() async
  // {
  //   QuerySnapshot querySnapshot = await followingRefrence.doc(currentUser.id).collection("userFollowing").get();
  //
  //   setState(() {
  //     followingsList = querySnapshot.docs.map((document) => document.id).toList();
  //   });
  // }
  retrieveTimeLine2() async
      {
        SnackBar snackBar = SnackBar(
          duration: Duration(seconds: 6),
          backgroundColor: Colors.grey,
          content: Container(
            height:2.0,
            child: linearProgressSnackbar(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
    QuerySnapshot querySnapshot2 = await timelineRefrence.doc(widget.gCurrentUser.id)
        .collection("timelinePosts").orderBy("timestamp", descending: true).startAfterDocument(startAfter).limit(limit).get();

      if(querySnapshot2.docs.length == 0 )
        {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          SnackBar snackBar = SnackBar(
                duration: Duration(milliseconds: 400),
                backgroundColor: Colors.grey,
                content: Text("Follow People to see their posts",textAlign: TextAlign.center, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
    else if(querySnapshot2.docs.length != 0 )
      {
        List<Post> allPosts = [];

        for(int i =0; i<=querySnapshot2.docs.length-1; i=i+1)
        {
          DocumentSnapshot ds2 = await postsReference
              .doc(querySnapshot2.docs[i]["ownerId"])
              .collection("usersPosts")
              .doc(querySnapshot2.docs[i]["postId"])
              .get();
          if(ds2.exists)
            {
              allPosts.add(Post.fromDocument(ds2));
            }
          if(i == querySnapshot2.docs.length-1)
          {
            setState(() {
              this.posts = this.posts + List.from(allPosts);
              if(allPosts.length >=4)
              {
                posts.insert(posts.length-3,AdmobService.createBannerAd()..load());
              }
              posts.insert(posts.length-1,AdmobService.createBannerAd()..load());
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            });
          }
        }



        //List<Post> allPosts = querySnapshot2.docs.map((document) => Post.fromDocument(document)).toList();

        setState(() {
                         //this.posts = posts + allPosts;
          // this.posts = this.posts + List.from(allPosts);
          // if(allPosts.length >=4)
          //   {
          //     posts.insert(posts.length-3,AdmobService.createBannerAd()..load());
          //   }
          // posts.insert(posts.length-1,AdmobService.createBannerAd()..load());
          //                       // for(int i = 4*count ; i <= posts.length;i = i+4)
                                //   {
                                //     posts.insert(i,AdmobService.createBannerAd()..load());
                                //   }
                                //count++;
          //ScaffoldMessenger.of(context).hideCurrentSnackBar();
          startAfter = querySnapshot2.docs[querySnapshot2.docs.length-1];
        });
      }
  }



  createUserTimeLine()
  {
    print(posts.toString());
    if(posts == null)
    {
      return circularProgress();
    }
    else if(posts.isEmpty)
      {
        return RefreshIndicator(
          onRefresh: () => retrieveTimeLine(),
          child: ListView(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height*0.20),
              controller: scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            children: <Widget>[Container(
              //color: Theme.of(context).accentColor.withOpacity(0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text("No Posts", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 50.0,fontFamily: "Signatra",),),
                  Icon(Icons.person_add_alt_1_rounded, color: Colors.blueGrey,size: 200.0,),
                  Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child:  Text("Follow your Friends to see their Creative Memes", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 20.0,),textAlign: TextAlign.center,),
                  ),
                ],
              ),
            ),]
          ),
        );
      }
    else
    {
      return ListView.builder(itemBuilder: (context, index){
        //print(posts);
        if(posts[index] is Post){
          return posts[index];
        }
        else{
          final Container adContainer = Container(
            alignment: Alignment.center,
            child: AdWidget(ad: posts[index] as BannerAd),//key: UniqueKey(),
            height: 100,
                  );
          return adContainer;
        }
      },itemCount: posts.length,
          controller: scrollController,physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()));
      //return ListView(children: posts,controller: scrollController,physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()));
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: CustomAppBar(
        appBar: header(context, isAppTitle: true,disappearedBackButton: true,),
        onTap: () {
          scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),

      //appBar: header(context, isAppTitle: true,disappearedBackButton: true,),

      body: RefreshIndicator(child: createUserTimeLine(), onRefresh: () => retrieveTimeLine(clearCachedData: true)),//.loadMore(clearCacheddata:true)
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onTap;
  final AppBar appBar;

  const CustomAppBar({Key key, this.onTap,this.appBar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  GestureDetector(onTap: onTap,child: appBar);
  }

  @override
  Size get preferredSize => new Size.fromHeight(kToolbarHeight);
}

