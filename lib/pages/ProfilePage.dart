import 'dart:async';

import 'package:buddiesgram/main.dart';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/EditProfilePage.dart';
import 'package:buddiesgram/pages/FollowersPage.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/PostTileWidget.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'FollowingPage.dart';

class ProfilePage extends StatefulWidget {
  final String userProfileId;

  ProfilePage({this.userProfileId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin<ProfilePage>
{
  final String currentOnlineUserId = currentUser?.id;
  bool loading = false;
  List<Post> postsListF=[];
  String postOrientation = "grid";
  int countTotalFollowers = 0;
  int countTotalFollowings = 0;
  int countTotalPosts=0;
  bool following = false;
  final scrollController = ScrollController();
  DocumentSnapshot startAfter;
  List<GridTile> gridTilesListF;
  List<GridTile> gridTilesList = [];
  int limit1=12;
  int limit2=9;

  @override
  void initState(){
    super.initState();
    getAllProfilePosts();
    getAllPosts();
    getAllFollowers();
    getAllFollowings();
    checkIfAlreadyFollowing();

    scrollController.addListener((){
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          getAllProfilePosts2();
          displayProfilePost();
        }
      }
    });
  }

  @override
  void dispose(){
    super.dispose();
    scrollController.dispose();
  }

  getAllFollowings() async
  {
    DocumentSnapshot dataSnapshot = await followingRefrence.doc(widget.userProfileId)
        .get();

    setState(() {
      countTotalFollowings = dataSnapshot["countFollowings"] - 1;
    });
  }
  getAllPosts() async
  {
    DocumentSnapshot dataSnapshot = await postsReference.doc(widget.userProfileId)
        .get();

    setState(() {
      countTotalPosts = dataSnapshot["countPosts"];
    });
  }

  checkIfAlreadyFollowing() async
  {
    DocumentSnapshot documentSnapshot = await followersRefrence
        .doc(widget.userProfileId).collection("userFollowers")
        .doc(currentOnlineUserId).get();

    setState(() {
      following = documentSnapshot.exists;
    });
  }

  getAllFollowers() async
  {
    DocumentSnapshot dataSnapshot = await followersRefrence.doc(widget.userProfileId)
        .get();

    setState(() {
      countTotalFollowers = dataSnapshot['countFollowers'] - 1 ;
    });
  }

  createProfileTopView(){
    return FutureBuilder(
      future: usersReference.doc(widget.userProfileId).get(),
      builder: (context, dataSnapshot){
        if(!dataSnapshot.hasData)
        {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        return Padding(
          padding: EdgeInsets.all(17.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.lightBlueAccent,
                    child:
                    CircleAvatar(
                      radius: 45.0,
                      backgroundColor: Colors.grey,
                      child: ClipOval(
                        child: SizedBox(
                          width: 180.0,
                          height: 180.0,
                          child: Image.network(user.url,fit: BoxFit.scaleDown),
                        ),
                      ),
                    ),
                  ),


                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            createColumns("posts", countTotalPosts),
                            TextButton(child: createColumns("followers", countTotalFollowers),onPressed : () => followersPage()
                              ,),
                            TextButton(child: createColumns("following", countTotalFollowings),onPressed: () => followingPage()
                              ,),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            createButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 13.0),
                child: Text(
                  user.username, style: TextStyle(fontSize: 14.0, color: Theme.of(context).cardColor),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 5.0),
                child: Text(
                  user.profileName, style: TextStyle(fontSize: 18.0, color: Theme.of(context).cardColor),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 3.0),
                child: Text(
                  user.bio, style: TextStyle(fontSize: 16.0, color: Theme.of(context).cardColor),
                ),
              ),
            ],
          ),
        );
        //dataSnapshot.clean();
      },
    );
  }
  followersPage(){
    if(following)
      {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FollowersPage(userProfileId: widget.userProfileId)));
      }
    else{
      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 800),
        backgroundColor: Colors.grey,
        content: Text("Follow user to see their Followers",textAlign: TextAlign.center, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
  followingPage(){
    if(following)
      {
        Navigator.push(context, MaterialPageRoute(builder: (context) => FollowingPage(userProfileId: widget.userProfileId)));

      }
    else{
      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 800),
        backgroundColor: Colors.grey,
        content: Text("Follow user to see their Followings",textAlign: TextAlign.center, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Column createColumns(String title, int count){
    return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                count.toString(),
                style: TextStyle(fontSize: 20.0, color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16.0, color: Theme.of(context).cardColor.withOpacity(0.7), fontWeight: FontWeight.w400),
                ),
              ),
            ],
    );
  }

  createButton()
  {
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if(ownProfile)
    {
      return Column(
        children: [
          createButtonTitleAndFunction(title: "Edit Profile", performFunction: editUserProfile,),
          // Switch.adaptive(value: true,activeColor: Colors.white, onChanged: (state){
          //
          //   print(state);
          // })
        ],
      );
    }
    else if(following)
    {
      return createButtonTitleAndFunction(title: "Unfollow", performFunction: controlUnfollowUser,);
    }
    else if(!following)
    {
      return createButtonTitleAndFunction(title: "Follow", performFunction: controlFollowUser,);
    }
  }

  controlUnfollowUser()
  async {
    setState(() {
      following = false;
    });

    followersRefrence.doc(widget.userProfileId)
        .collection("userFollowers")
        .doc(currentOnlineUserId)
        .get()
        .then((document){
      if(document.exists)
      {
        document.reference.delete();
      }
    });

    followingRefrence.doc(currentOnlineUserId)
        .collection("userFollowing")
        .doc(widget.userProfileId)
        .get()
        .then((document){
      if(document.exists)
      {
        document.reference.delete();
      }
    });

    activityFeedReference.doc(widget.userProfileId).collection("feedItems")
        .doc(currentOnlineUserId).get().then((document){
      if(document.exists)
      {
        document.reference.delete();
      }
    });
  }

  controlFollowUser()
  async {
    setState(() {
      following = true;
    });

    followersRefrence.doc(widget.userProfileId).collection("userFollowers")
        .doc(currentOnlineUserId)
        .set({"userId": currentOnlineUserId,"userEmailId": currentUser.email,});

    followingRefrence.doc(currentOnlineUserId).collection("userFollowing")
        .doc(widget.userProfileId)
        .set({"ownerId": widget.userProfileId,});


    activityFeedReference.doc(widget.userProfileId)
        .collection("feedItems").doc(currentOnlineUserId)
        .set({
      "type": "follow",
      "ownerId": widget.userProfileId,
      "username": currentUser.username,
      "timestamp": DateTime.now(),
      "userProfileImg": currentUser.url,
      "userId": currentOnlineUserId,
    });
  }

  Container createButtonTitleAndFunction({String title, Function performFunction}){
    return Container(
      padding: EdgeInsets.only(top: 3.0),
      child: TextButton(
        onPressed: performFunction,
        child: Container(
          width: 150.0,
          height: 26.0,
          child: Text(title, style: TextStyle(color: following ? Colors.black : Colors.black, fontWeight: FontWeight.bold),),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: following ? Colors.blueGrey : Colors.lightBlueAccent,
            border: Border.all(color: following ? Colors.grey : Colors.grey),
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
      ),
    );
  }

  editUserProfile(){
    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage(currentOnlineUserId: currentOnlineUserId)));
  }

  Future<Null> _refreshProfilePage() async{
    getAllPosts();
    getAllFollowers();
    getAllFollowings();
    // getAllProfilePosts();
    //createProfileTopView();
    //displayProfilePost();
    getAllProfilePosts();

    // checkIfAlreadyFollowing();
    // getAllProfilePosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CustomAppBar(
        appBar: header(context, strTitle: "Profile",),

        onTap: () {
          scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
      //appBar: header(context, strTitle: "Profile",),
      body:
      RefreshIndicator(
        onRefresh: _refreshProfilePage,
        child:
      ListView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: <Widget>[
            createProfileTopView(),
            Divider(),
            createListAndGridPostOrientation(),
            Divider(height: 0.0,),
            displayProfilePost(),
          ],
      ),
    ),
    );
  }


  displayProfilePost()
  {
    bool ownProfile = currentOnlineUserId == widget.userProfileId;
    if(ownProfile)
    {
      if(loading)
      {
        return circularProgress();
      }
      else if(postsListF.isEmpty)
      {
        return Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(30.0),
                child: Icon(Icons.photo_library, color: Colors.blueGrey, size: 200.0,),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Text("Post your First Meme", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 60.0,fontFamily: "Signatra",),textAlign: TextAlign.center,),
              ),
            ],
          ),
        );
      }
      else if(postOrientation == "grid")
      {
        return GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          mainAxisSpacing: 1.5,
          crossAxisSpacing: 1.5,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: gridTilesListF,
        );
      }
      else if(postOrientation == "list")
      {
        return Column(
          children: postsListF,
        );
      }
    }
    else if(!following)
    {
      return Container(
        alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Center(child: Text("Follow this account to see their Memes", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 20.0, fontWeight: FontWeight.bold),)),
          )
      );
    }
    if(loading)
    {
      return circularProgress();
    }
    else if(postsListF.isEmpty)
    {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(30.0),
              child: Icon(Icons.photo_library, color: Colors.blueGrey, size: 200.0,),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text("No Posts", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 40.0, fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      );
    }
    else if(postOrientation == "grid")
    {

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTilesListF,
      );
    }
    else if(postOrientation == "list")
    {
      return Column(
        children: postsListF,
      );
    }
  }

  getAllProfilePosts() async {
    setState(() {
      loading = true;
    });

    QuerySnapshot querySnapshot = await postsReference.doc(widget.userProfileId).collection("usersPosts").orderBy("timestamp", descending: true).limit(limit1).get();

    List<Post> postsList = querySnapshot.docs.map((documentSnapshot) => Post.fromDocument(documentSnapshot)).toList();
    gridTilesListF = [];

    setState(() {
      if(querySnapshot!=null)
      {
        if(querySnapshot.docs.length != 0)
        {
          startAfter = querySnapshot.docs[querySnapshot.docs.length-1];
        }
      }
      loading = false;
      this.postsListF = postsList;
      postsListF.forEach((eachPost){
        gridTilesListF.add(GridTile(child: PostTile(eachPost)));
      });

    });
  }

  getAllProfilePosts2() async {
    SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey,
      content: Container(
        height:2.0,
        child: linearProgressSnackbar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    QuerySnapshot querySnapshot2 = await postsReference.doc(widget.userProfileId)
        .collection("usersPosts").orderBy("timestamp", descending: true).startAfterDocument(startAfter)
        .limit(limit2).get();
    if(querySnapshot2.docs.length == 0 )
    {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text("No more Posts",textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    else if(querySnapshot2.docs.length != 0 )
    {
      gridTilesList = [];
      List<Post> postsList =  querySnapshot2.docs.map((documentSnapshot) => Post.fromDocument(documentSnapshot)).toList();

      setState(() {

        if(querySnapshot2!=null)
        {
          if(querySnapshot2.docs.length != 0)
          {
            startAfter = querySnapshot2.docs[querySnapshot2.docs.length-1];
          }
        }
        postsList.forEach((eachPost){
          this.gridTilesList.add(GridTile(child: PostTile(eachPost)));
        });
        this.postsListF = postsListF + postsList;
        this.gridTilesListF = gridTilesListF + gridTilesList;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

      });
    }
  }


  createListAndGridPostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: ()=> setOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == "grid" ? Colors.lightBlueAccent : Theme.of(context).cardColor
        ),
        IconButton(
          onPressed: ()=> setOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == "list" ?  Colors.lightBlueAccent : Theme.of(context).cardColor
        ),
      ],
    );
  }

  setOrientation(String orientation)
  {
    setState(() {
      this.postOrientation = orientation;
    });
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


