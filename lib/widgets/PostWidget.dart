import 'dart:async';
import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/CommentsPage.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:buddiesgram/pages/LikePage.dart';

class Post extends StatefulWidget
{
  final String postId;
  final String ownerId;
  final String username;
  final String description;
  final String location;
  final String url;
  final int countLike;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.description,
    this.location,
    this.url,
    this.countLike,
  });

  factory Post.fromDocument(DocumentSnapshot documentSnapshot){
    return Post(
      postId: documentSnapshot["postId"],
      ownerId: documentSnapshot["ownerId"],
      username: documentSnapshot["username"],
      description: documentSnapshot["description"],
      location: documentSnapshot["location"],
      url: documentSnapshot["url"],
      countLike: documentSnapshot["countLike"],
    );
  }


  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    description: this.description,
    location: this.location,
    url: this.url,
    countLike: this.countLike,
  );
}






class _PostState extends State<Post>
{
  final String postId;
  final String ownerId;
  int countLike;
  final String username;
  final String description;
  final String location;
  final String url;
  bool isLiked=false;
  bool showHeart = false;
  final String currentOnlineUserId = currentUser?.id;


  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.description,
    this.location,
    this.url,
    this.countLike,
  });

  @override
  void initState(){
    super.initState();
    checkIfAlreadyLike();
  }

  checkIfAlreadyLike() async
  {
    DocumentSnapshot documentSnapshot = await postsReference
        .doc(ownerId).collection("usersPosts")
        .doc(postId).collection("like").doc(currentOnlineUserId).get();

    setState(() {
      isLiked = documentSnapshot.exists;
    });
  }


  @override
  Widget build(BuildContext context)
  {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>
        [
          createPostHead(),
          createPostPicture(),
          createPostFooter()
        ],
      ),
    );
  }


  createPostHead(){
    return FutureBuilder(
      future: usersReference.doc(ownerId).get(),
      builder: (context, dataSnapshot){
        if(!dataSnapshot.hasData)
        {
          return circularProgress();
        }
        User user = User.fromDocument(dataSnapshot.data);
        bool isPostOwner = currentOnlineUserId == ownerId;

        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.lightBlueAccent,
                child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.url),),//NetworkImage(user.url)
              ),

              title: GestureDetector(
                onTap: ()=> displayUserProfile(context, userProfileId: user.id),
                child: Text(
                  user.username,
                  style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold), //white
                ),
              ),
              subtitle: Text(location, style: TextStyle(color: Theme.of(context).cardColor),),//white
              trailing: isPostOwner ? IconButton(
                icon: Icon(Icons.more_vert, color: Theme.of(context).cardColor,),//white
                onPressed: ()=> controlPostDelete(context),
              ) : Text(""),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Container(
                //   margin: EdgeInsets.only(left: 20.0, bottom: 10.0),
                //   child: Text("$username  : ", style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),),//white
                // ),
                Container(
                  margin: EdgeInsets.only(left: 20.0, bottom: 5.0,),
                child: Text(description, style: TextStyle(color: Theme.of(context).cardColor),),//white
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  controlPostDelete(BuildContext mContext)
  {
    return showDialog(
        context: mContext,
        builder: (context)
        {
          return SimpleDialog(
            title: Text("What do you want?", style: TextStyle(color: Theme.of(context).cardColor),),//white
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Delete", style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),),//white
                onPressed: ()
                {
                  Navigator.pop(context);
                  removeUserPost();
                },
              ),
              SimpleDialogOption(
                child: Text("Cancel", style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),),//white
                onPressed: ()=> Navigator.pop(context),
              ),
            ],
          );
        }
    );
  }

  removeUserPost() async
  {
    postsReference.doc(ownerId).collection("usersPosts").doc(postId).get()
        .then((document){
      if(document.exists)
      {
        document.reference.delete();
      }
    });
    commentsRefrence.doc(postId).get().then((document){
        if(document.exists)
        {
            document.reference.delete();
        }
        });

    storageReference.child("post_$postId.jpg").delete();

    QuerySnapshot querySnapshot = await activityFeedReference.doc(ownerId)
        .collection("feedItems").where("postId", isEqualTo: postId).get();
    querySnapshot.docs.forEach((document){
      if(document.exists)
      {
        document.reference.delete();
      }
    });
    QuerySnapshot commentsQuerySnapshot = await commentsRefrence.doc(postId).collection("comments").get();
    commentsQuerySnapshot.docs.forEach((document){
      if(document.exists)
      {
        document.reference.delete();
      }
    });
    SnackBar snackBar = SnackBar(content: Text("Image Deleated, kindly refresh this page. "));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  displayUserProfile(BuildContext context, {String userProfileId})
  {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }

  removeLike(){
    bool isNotPostOwner = currentOnlineUserId != ownerId;

    if(isNotPostOwner){
      activityFeedReference.doc(ownerId).collection("feedItems").doc(postId).get().then((document){
        if(document.exists)
        {
          document.reference.delete();
        }
      });
    }
  }

  addLike()
  {
    bool isNotPostOwner = currentOnlineUserId != ownerId;

    if(isNotPostOwner)
    {
      activityFeedReference.doc(ownerId).collection("feedItems").doc(postId).set({
        "type": "like",
        "username": currentUser.username,
        "userEmailId":currentUser.email,
        "userId": currentUser.id,
        "timestamp": DateTime.now(),
        "url": url,
        "postId": postId,
        "userProfileImg": currentUser.url,
      });
    }
  }

  controlUserLikePost() async {
    if(isLiked)//_liked
    {
      postsReference.doc(ownerId).collection("usersPosts").doc(postId).collection("like").doc(currentOnlineUserId).get()
          .then((document){
        if(document.exists){
          document.reference.delete();
        }
      });


      removeLike();

      setState(() {
        countLike = countLike - 1;
        isLiked = false;
      });
    }
    else if(!isLiked)
    {
      postsReference.doc(ownerId).collection("usersPosts").doc(postId).collection("like").doc(currentOnlineUserId).set({"id":currentOnlineUserId,
      "email":currentUser.email,});

      addLike();

      setState(() {
        countLike = countLike + 1;
        isLiked = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), (){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  createPostPicture()
  {
    return GestureDetector(
      onDoubleTap: controlUserLikePost,
      child: Stack
        (
        alignment: Alignment.center,
        children: <Widget>
        [
          Image.network(url),
          showHeart ? Icon(Icons.favorite, size: 140.0, color: Colors.lightBlueAccent,) : Text(""),
        ],
      ),
    );
  }


  createPostFooter()
  {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: ()=> controlUserLikePost(),
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.lightBlueAccent,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: ()=> displayComments(context, postId: postId, ownerId: ownerId, url: url),
              child: Icon(Icons.chat_bubble_outline, size: 28.0, color: Theme.of(context).cardColor,),//comment box icon
            ),
          ],
        ),
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: () =>  Navigator.push(context, MaterialPageRoute(builder: (context) => LikePage(ownerId: ownerId,postId: postId,))),
              child: Container(
                margin: EdgeInsets.only(left: 20.0),
                child: Text(
                  "$countLike likes",
                  style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold),//white count like
                ),
              ),
            ),
          ],
        ),

      ],
    );
  }



  displayComments(BuildContext context, {String postId, String ownerId, String url})
  {
    Navigator.push(context, MaterialPageRoute(builder: (context)
    {
      return CommentsPage(postId: postId, postOwnerId: ownerId, postImageUrl: url);
    }
    ));
  }
}

