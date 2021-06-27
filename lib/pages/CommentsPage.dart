import 'dart:ui';

import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;
import 'package:uuid/uuid.dart';

import 'ProfilePage.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;

  CommentsPage({this.postId, this.postOwnerId, this.postImageUrl});

  @override
  CommentsPageState createState() => CommentsPageState(
      postId: postId, postOwnerId: postOwnerId, postImageUrl: postImageUrl);
}

class CommentsPageState extends State<CommentsPage> {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;
  String commentId = Uuid().v4();
  Stream<QuerySnapshot> commentsFinal;
  TextEditingController commentTextEditingController = TextEditingController();
  DocumentSnapshot startAfter;
  //List<Comment> commentList;
  List<Comment> commentListFinal;
  final scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  CommentsPageState({this.postId, this.postOwnerId, this.postImageUrl});

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          retriveComments2();
        }
      }
    });
    retriveComments();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  retriveComments2() async {
    SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey,
      content: Container(
        height: 2.0,
        child: linearProgressSnackbar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    QuerySnapshot commentQuery2 = await commentsRefrence
        .doc(postId)
        .collection("comments")
        .orderBy("timestamp", descending: true)
        .startAfterDocument(startAfter)
        .limit(2)
        .get();
    print("second");
    if (commentQuery2.docs.length == 0) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text(
          "No more Comments",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    List<Comment> commentList = [];
    commentQuery2.docs.forEach((document) {
      commentList.add(Comment.fromDocument(document));
    });
    setState(() {
      if (commentQuery2 != null) {
        if (commentQuery2.docs.length != 0) {
          startAfter = commentQuery2.docs[commentQuery2.docs.length - 1];
        }
      }
      this.commentListFinal = commentListFinal + commentList;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  retriveComments({bool clearCachedData: false}) async {
    if (clearCachedData) {
      commentListFinal = null;
    }
    QuerySnapshot commentQuery = await commentsRefrence
        .doc(postId)
        .collection("comments")
        .orderBy("timestamp", descending: true)
        .limit(8)
        .get();

    List<Comment> commentList = [];
    commentQuery.docs.forEach((document) {
      commentList.add(Comment.fromDocument(document));
    });

    setState(() {
      if (commentQuery != null) {
        if (commentQuery.docs.length != 0) {
          startAfter = commentQuery.docs[commentQuery.docs.length - 1];
        }
      }
      this.commentListFinal = commentList;
    });
  }

  retrieveComments() {
    if (commentListFinal == null) {
      return circularProgress();
    }
    // List<Comment> comments = [];
    // dataSnapshot.data.documents.forEach((document){
    //   comments.add(Comment.fromDocument(document));
    // });

    if (commentListFinal.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => retriveComments(clearCachedData: true),
        child: Center(
          child: ListView(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.20),
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              children: <Widget>[
                Container(
                  // color: Theme.of(context).accentColor.withOpacity(0.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "No comments",
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 50.0,
                          fontFamily: "Signatra",
                        ),
                      ),
                      Icon(
                        Icons.comment_rounded,
                        color: Colors.blueGrey,
                        size: 200.0,
                      ),
                    ],
                  ),
                ),
              ]),
        ),
      );
    }

    return ListView(
      children: commentListFinal,
      controller: scrollController,
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    );
  }

  saveComment() {
    commentsRefrence.doc(postId).collection("comments").doc(commentId).set({
      "username": currentUser.username,
      "comment": commentTextEditingController.text,
      "timestamp": DateTime.now(),
      "url": currentUser.url,
      "userId": currentUser.id,
      "postId": postId,
      "commentId": commentId,
      "emailId": currentUser.email,
    });
    setState(() {
      commentId = Uuid().v4();
    });

    bool isNotPostOwner = postOwnerId != currentUser.id;
    if (isNotPostOwner) {
      activityFeedReference.doc(postOwnerId).collection("feedItems").add({
        "type": "comment",
        "commentData": commentTextEditingController.text,
        "postId": postId,
        "userId": currentUser.id,
        "username": currentUser.username,
        "userProfileImg": currentUser.url,
        "url": postImageUrl,
        "timestamp": timestamp,
      });
    }
    commentTextEditingController.clear();
    final snackBar =
        SnackBar(content: Text('Comment Inserted, Refresh this page'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBar: header(context, strTitle: "Comments"),
        onTap: () {
          scrollController.animateTo(0,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),

      //appBar: header(context, strTitle: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(
            child: RefreshIndicator(
                child: retrieveComments(),
                onRefresh: () => retriveComments(clearCachedData: true)),
          ),
          //RefreshIndicator(child: retrieveComments(), onRefresh: () => retriveComments(clearCachedData: true)),),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentTextEditingController,
              decoration: InputDecoration(
                labelText: "Write comment here...",
                labelStyle:
                    TextStyle(color: Theme.of(context).cardColor), //white
                enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).cardColor)), //grey
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Theme.of(context).cardColor)), //white
              ),
              style: TextStyle(color: Theme.of(context).cardColor), //white
            ),
            trailing: OutlineButton(
              onPressed: saveComment,
              borderSide: BorderSide.none,
              child: Text(
                "Publish",
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String url;
  final String comment;
  final Timestamp timestamp;
  final String postId;
  final String commentId;

  Comment(
      {this.username,
      this.userId,
      this.url,
      this.comment,
      this.timestamp,
      this.postId,
      this.commentId});

  factory Comment.fromDocument(DocumentSnapshot documentSnapshot) {
    return Comment(
      username: documentSnapshot["username"],
      userId: documentSnapshot["userId"],
      url: documentSnapshot["url"],
      comment: documentSnapshot["comment"],
      timestamp: documentSnapshot["timestamp"],
      postId: documentSnapshot["postId"],
      commentId: documentSnapshot["commentId"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.0),
      child: Container(
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(20),
        //   color: Colors.blueGrey,
        // ),
        //color: Colors.lightBlueAccent,
        child: Column(
          children: <Widget>[
            ListTile(
              title: GestureDetector(
                onTap: () => displayUserProfile(context, userProfileId: userId),
                child: RichText(
                  //overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).cardColor), //black
                    children: [
                      TextSpan(
                        text: username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: " : "),
                      TextSpan(
                        text: comment,
                      ), //,style: TextStyle(fontWeight: FontWeight.bold),
                    ],
                  ),
                ),
              ),
              //title: Text(username + ":  " + comment, style: TextStyle(fontSize: 18.0, color: Colors.black),),
              leading: GestureDetector(
                onTap: () => displayUserProfile(context, userProfileId: userId),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.lightBlueAccent,
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(url),
                  ),
                ),
              ),
              // leading: CircleAvatar(
              //   backgroundImage: CachedNetworkImageProvider(url),
              // ),
              subtitle: Text(
                tAgo.format(timestamp.toDate()),
                style:
                    TextStyle(color: Theme.of(context).cardColor, fontSize: 11),
              ), //black
              trailing: userId == currentUser.id
                  ? IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: () => controlCommentDelete(context),
                    )
                  : Text(""),
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

  controlCommentDelete(BuildContext mContext) {
    return showDialog(
        context: mContext,
        builder: (context) {
          return SimpleDialog(
            title: Text(
              "What do you want?",
              style: TextStyle(color: Theme.of(context).cardColor),
            ),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  "Delete",
                  style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  removeUserComment();
                  Navigator.pop(context);
                  final snackBar = SnackBar(
                      content: Text('Comment Deleted, Refresh this page'));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
              ),
              SimpleDialogOption(
                child: Text(
                  "Cancel",
                  style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  removeUserComment() async {
    commentsRefrence
        .doc(postId)
        .collection("comments")
        .doc(commentId)
        .get()
        .then((documents) {
      if (documents.exists) {
        documents.reference.delete();
      }
    });
  }
}
