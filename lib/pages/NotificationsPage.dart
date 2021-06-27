import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/PostScreenPage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tAgo;

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with AutomaticKeepAliveClientMixin<NotificationsPage> {
  final scrollController = ScrollController();
  DocumentSnapshot startAfter;
  List<NotificationsItem> notificationList;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int limit = 9;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    retrieveNotifications();

    scrollController.addListener((){
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          retrieveNotifications2();
        }
      }
    });


  }
  @override
  void dispose(){
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      key: _scaffoldKey,

      appBar: CustomAppBar(
        appBar: header(context, strTitle: "Notifications",disappearedBackButton: true,),
        onTap: () {
          scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),

      //appBar: header(context, strTitle: "Notifications",disappearedBackButton: true,),
      body: RefreshIndicator(child: createUserNotification(), onRefresh: () => retrieveNotifications(clearCachedData: true)),

    );
  }
  createUserNotification()
  {
    if(notificationList == null)
          {
            return circularProgress();
          }
          else if(notificationList.isEmpty)//dataSnapshot.data.toString() == "[]"
        {
      return RefreshIndicator(
        onRefresh: () => retrieveNotifications(),
        child: Center(
          child: ListView(
              padding: EdgeInsets.only(top: MediaQuery
                  .of(context)
                  .size
                  .height * 0.25),
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              children: <Widget>[Container(
                // color: Theme
                //     .of(context)
                //     .accentColor
                //     .withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text("No notifications", style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 50.0,
                      fontFamily: "Signatra",),),
                    Icon(Icons.notifications_active_outlined,
                      color: Colors.blueGrey, size: 200.0,),
                  ],
                ),
              ),
              ]
          ),
        ),
      );
    }

          else{
            return ListView(children: notificationList, controller: scrollController,physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()));//dataSnapshot.data
          }
  }

  retrieveNotifications({bool clearCachedData : false}) async
  {
    if(clearCachedData){
      setState(() {
        notificationList = null;
      });
    }
    QuerySnapshot querySnapshot = await activityFeedReference.doc(currentUser.id)
        .collection("feedItems").orderBy("timestamp", descending: true)
        .limit(limit).get();
    print("first");
    List<NotificationsItem> notificationsItems = querySnapshot.docs.map((document) => NotificationsItem.fromDocument(document)).toList();
    setState(() {
      if(querySnapshot!=null)
        {
          if(querySnapshot.docs.length != 0)
          {
            startAfter = querySnapshot.docs[querySnapshot.docs.length-1];
          }
        }
      this.notificationList = notificationsItems;
    });
    //return notificationsItems;
  }

  retrieveNotifications2() async
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


    QuerySnapshot querySnapshot2 = await activityFeedReference.doc(currentUser.id)
        .collection("feedItems").orderBy("timestamp", descending: true)
        .startAfterDocument(startAfter)
        .limit(limit).get();
    print("second");

    if(querySnapshot2.docs.length == 0 )
    {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text("No more notifications",textAlign: TextAlign.center, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    else if(querySnapshot2.docs.length != 0){
    List<NotificationsItem> notificationsItems = querySnapshot2.docs.map((document) => NotificationsItem.fromDocument(document)).toList();

      setState(() {
      if(querySnapshot2!=null)
        {
          if(querySnapshot2.docs.length != 0)
          {
              startAfter = querySnapshot2.docs[querySnapshot2.docs.length-1];
          }
        }
      this.notificationList = notificationList + notificationsItems;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}

String notificationItemText;
Widget mediaPreview;

class NotificationsItem extends StatelessWidget
{
  final String username;
  final String type;
  final String commentData;
  final String postId;
  final String userId;
  final String userProfileImg;
  final String url;
  final Timestamp timestamp;

  NotificationsItem({this.username, this.type, this.commentData, this.postId, this.userId, this.userProfileImg, this.url, this.timestamp});

  factory NotificationsItem.fromDocument(DocumentSnapshot documentSnapshot)
  {
    if(documentSnapshot["type"] == 'follow')
      {
        return NotificationsItem(
          username: documentSnapshot["username"],
          type: documentSnapshot["type"],
          userId: documentSnapshot["userId"],
          userProfileImg: documentSnapshot["userProfileImg"],
          timestamp: documentSnapshot["timestamp"],
        );
      }
    else if(documentSnapshot["type"] == "like")
      {
        return NotificationsItem(
          username: documentSnapshot["username"],
          type: documentSnapshot["type"],
          postId: documentSnapshot["postId"],
          userId: documentSnapshot["userId"],
          userProfileImg: documentSnapshot["userProfileImg"],
          url: documentSnapshot["url"],
          timestamp: documentSnapshot["timestamp"],
        );
      }
    else if(documentSnapshot["type"] == "comment")
      {
        return NotificationsItem(
          username: documentSnapshot["username"],
          type: documentSnapshot["type"],
          commentData: documentSnapshot["commentData"],
          postId: documentSnapshot["postId"],
          userId: documentSnapshot["userId"],
          userProfileImg: documentSnapshot["userProfileImg"],
          url: documentSnapshot["url"],
          timestamp: documentSnapshot["timestamp"],
        );
      }

    return NotificationsItem(
      username: documentSnapshot["username"],
      type: documentSnapshot["type"],
      //commentData: documentSnapshot["commentData"],
      //postId: documentSnapshot["postId"],
      userId: documentSnapshot["userId"],
      userProfileImg: documentSnapshot["userProfileImg"],
      //url: documentSnapshot["url"],
      timestamp: documentSnapshot["timestamp"],
    );
  }

  @override
  Widget build(BuildContext context)
  {
    configureMediaPreview(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Container(
      // decoration: BoxDecoration(
      // borderRadius: BorderRadius.circular(20),
      //   color: Colors.black,//blueGrey
      // ),

        child: ListTile(
          title: GestureDetector(
            onTap: ()=> displayUserProfile(context, userProfileId: userId),
            child: RichText(
              //overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14.0, color: Theme.of(context).cardColor),//black
                children: [
                  TextSpan(text: username, style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: " $notificationItemText"),
                ],
              ),
            ),
          ),
          leading: GestureDetector(
            onTap: ()=> displayUserProfile(context, userProfileId: userId),
            child:CircleAvatar(
              radius: 22,
              backgroundColor: Colors.lightBlueAccent,
              child: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(userProfileImg),
              ),
            ),


          ),
          subtitle: Text(tAgo.format(timestamp.toDate()), overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).cardColor),),
          trailing: mediaPreview,
        ),
      ),
    );
  }

  configureMediaPreview(context)
  {
    if(type == "comment"  ||  type == "like")
    {
      mediaPreview = GestureDetector(
        //onTap: ()=> displayOwnProfile(context, userProfileId: currentUser.id),
        onTap: ()=> displayOwnPost(context, userPostId: currentUser.id, postId: postId),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.lightBlueAccent)
          ),
          height: 60.0,
          width: 60.0,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(fit: BoxFit.contain, image: CachedNetworkImageProvider(url)),
              ),
            ),
          ),
        ),
      );
    }
    else
    {
      mediaPreview = Text("");
    }

    if(type == "like")
    {
      notificationItemText = "liked your post.";
    }
    else if(type == "comment")
    {
      notificationItemText = "replied: $commentData";
    }
    else if(type == "follow")
    {
      notificationItemText = "started following you.";
    }
    else
    {
      notificationItemText = "Error, Unknown type = $type";
    }
  }

  displayOwnPost(BuildContext context, {String userPostId, String postId})
  {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PostScreenPage(userId: currentUser.id, postId: postId, )));
  }

  displayUserProfile(BuildContext context, {String userProfileId})
  {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId)));
  }
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

