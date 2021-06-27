import 'package:buddiesgram/models/user.dart';
import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/pages/ProfilePage.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with AutomaticKeepAliveClientMixin<SearchPage> {

  TextEditingController searchTextEditingController = TextEditingController();
  List<UserResult> finalSearchResults;
  List<UserResult> finalTrendingResults;
  final scrollController = ScrollController();
  final scrollController2 = ScrollController();
  int limit=9;
  int limit2 = 5;
  DocumentSnapshot startAfter;
  String str2;
  int count=0;


  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.atEdge) {
        if (scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          controlSearching2(str2);
        }
      }
    });
    tredingPages();
  }
  @override
  void dispose(){
    super.dispose();
    scrollController.dispose();
  }


  emptyTheTextFormField(){
    searchTextEditingController.clear();
    setState(() {
      finalSearchResults=null;
    });
  }
  controlSearching(String str, {bool clearCachedData = false}) async {
    if(str == "")
      {
        setState(() {
          finalSearchResults=null;
        });
      }
    else{
      List<UserResult> searchUsersResult=[];

      QuerySnapshot allUsersProfile = await usersReference
          .where("searchName", isGreaterThanOrEqualTo: str.toLowerCase().replaceAll(' ', ''))
          .orderBy("searchName")
          .limit(limit)
          .get();

      allUsersProfile.docs.forEach((document)
      {
        User eachUser = User.fromDocument(document);
        UserResult userResult = UserResult(eachUser);
        searchUsersResult.add(userResult);
      });

      setState(() {
        if(allUsersProfile!=null)
        {
          if(allUsersProfile.docs.length != 0)
          {
            startAfter = allUsersProfile.docs[allUsersProfile.docs.length-1];
          }
        }
        finalSearchResults = searchUsersResult;
        str2 = str;
      });
    }
  }

  controlSearching2(String str) async {
    SnackBar snackBar = SnackBar(
      duration: Duration(seconds: 3),
      backgroundColor: Colors.grey,
      content: Container(
        height:2.0,
        child: linearProgressSnackbar(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    List<UserResult> searchUsersResult=[];
    QuerySnapshot allUsersProfile2 = await usersReference
        .where("searchName", isGreaterThanOrEqualTo: str.toLowerCase().replaceAll(' ', ''))
        .orderBy("searchName")
        .startAfterDocument(startAfter)
        .limit(limit2)
        .get();

    if(allUsersProfile2.docs.length == 0 )
    {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      SnackBar snackBar = SnackBar(
        duration: Duration(milliseconds: 400),
        backgroundColor: Colors.grey,
        content: Text("No more Users",textAlign: TextAlign.center, style: TextStyle(color: Colors.black), overflow: TextOverflow.ellipsis,),);
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    else if(allUsersProfile2.docs.length != 0) {
      allUsersProfile2.docs.forEach((document) {
        User eachUser = User.fromDocument(document);
        UserResult userResult = UserResult(eachUser);
        searchUsersResult.add(userResult);
      });
      setState(() {
        if (allUsersProfile2 != null) {
          if (allUsersProfile2.docs.length != 0) {
            startAfter = allUsersProfile2.docs[allUsersProfile2.docs.length - 1];
          }
        }
        finalSearchResults = finalSearchResults + searchUsersResult;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        //print("control searching 2 set state");
      });
    }
  }


  AppBar searchPageHeader(){
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      brightness: Brightness.dark,
      title: TextFormField(

        style: TextStyle(fontSize: 18.0, color: Theme.of(context).cardColor),
        controller: searchTextEditingController,
        onChanged: controlSearching,
        decoration: InputDecoration(
          hintText: "Search Profile Name here...",
          hintStyle: TextStyle(color: Theme.of(context).cardColor),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).cardColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).cardColor),
          ),
          //filled: true,
          prefixIcon: Icon(Icons.person_pin, color: Theme.of(context).cardColor, size: 30.0,),
          suffixIcon: IconButton(icon: Icon(Icons.clear, color: Theme.of(context).cardColor,),onPressed: emptyTheTextFormField,)
        ),
      ),
    );
  }

  tredingPages({bool clearCachedData=false}) async {
    if(clearCachedData)
      {
        finalTrendingResults=null;
      }
    QuerySnapshot allTrenders = await postsReference.orderBy("countPosts", descending: true).limit(8).get();
    List<UserResult> searchTrendingResult = [];
    if(allTrenders.docs.length==0)
      {
        this.finalTrendingResults=searchTrendingResult;
      }
    for(int i =0; i<=allTrenders.docs.length-1; i=i+1)
      {
        QuerySnapshot ds = await usersReference.where("id", isEqualTo: allTrenders.docs[i].id).get();
        User eachUser = User.fromDocument(ds.docs[0]);
        UserResult userResult = UserResult(eachUser);
        searchTrendingResult.insert(i, userResult);
        if(i == allTrenders.docs.length-1){
          setState(() {
            this.finalTrendingResults = searchTrendingResult;
          });
        }
      }
  }

  Container displayNoSearchResultScreen(){
    return Container(
      child: RefreshIndicator(child: createTrendingList(),onRefresh: () => tredingPages(clearCachedData : true)),// onRefresh: () => retriveName()
    );

  }

  Container displayUsersFoundScreen(){
    return Container(
      child: RefreshIndicator(child: createUserNameList(),onRefresh: () => controlSearching(str2,clearCachedData : true)),// onRefresh: () => retriveName()
    );

   }

   createTrendingList(){
     if(finalTrendingResults == null){
       return circularProgress();
     }
     else{
       return ListView(
         controller: scrollController2,
         physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
         children: [
           Container(child: Text("Trending Memers",textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 50, fontFamily: "Signatra"),),),
             Container(
               height: MediaQuery.of(context).size.height,
               child:ListView(children: finalTrendingResults,
             controller: scrollController2,
             ),
             ),
         ],
       );

     }
   }

  createUserNameList(){
    if(finalSearchResults == null){
            return circularProgress();
          }

          if(finalSearchResults.toString() == "[]")
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
                      Text("No user found", style: TextStyle(color: Colors.lightBlueAccent, fontSize: 50.0,fontFamily: "Signatra",),),
                    ],
                  ),
                ),]
              ),
            );
          }


          return ListView(children: finalSearchResults,
            controller: scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),);
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.black,
      appBar: searchPageHeader(),
      body: finalSearchResults == null ? displayNoSearchResultScreen() : displayUsersFoundScreen(),
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
          //     borderRadius: BorderRadius.circular(20),
          // color: Colors.blueGrey,
          // ),

        child: Column(
          children: <Widget>[
            GestureDetector(
              onTap: ()=>  displayUserProfile(context, userProfileId: eachUser.id),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.lightBlueAccent,
                  child: CircleAvatar(backgroundColor: Theme.of(context).cardColor, backgroundImage: CachedNetworkImageProvider(eachUser.url),radius: 23,),
                ),

                title: Text(eachUser.profileName, style: TextStyle(
                  color: Theme.of(context).cardColor, fontSize: 15.0, fontWeight: FontWeight.bold,

                ),
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
