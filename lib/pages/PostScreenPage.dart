import 'package:buddiesgram/pages/HomePage.dart';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:buddiesgram/widgets/PostWidget.dart';
import 'package:buddiesgram/widgets/ProgressWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_service.dart';

class PostScreenPage extends StatelessWidget
{
  final String postId;
  final String userId;
  final scrollController = ScrollController();


  PostScreenPage({
    this.userId,
    this.postId
  });


  @override
  Widget build(BuildContext context)
  {
    return FutureBuilder(
      future: postsReference.doc(userId).collection("usersPosts").doc(postId).get(),
      builder: (context, dataSnapshot)
      {
        if(!dataSnapshot.hasData)
        {
          return circularProgress();
        }

        Post post = Post.fromDocument(dataSnapshot.data);
        return Center(
            child: Scaffold(
              appBar: header(context, strTitle: post.description),
              body: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: <Widget>[
                  Container(
                    child: post,
                  ),
                ],
              ),
              bottomNavigationBar: Container(
                alignment: Alignment.center,
                child: AdWidget(key: UniqueKey(), ad: AdmobService.createBannerAdSmall()..load(),),//AdmobService.createBannerAd()..load()
                height: 50,
              ),
            ),
        );
      },
    );
  }
}
