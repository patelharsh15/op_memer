const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();




exports.onCreateActivityFeedItem = functions.firestore
.document('/feed/{userId}/feedItems/{activityFeedItem}')
.onCreate(async (snapshot, context) =>
{
    const userId = context.params.userId;
    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();


    const androidNotificationToken = doc.data().androidNotificationToken;
    const createActivityFeedItem = snapshot.data();

    if(androidNotificationToken)
    {
        sendNotification(androidNotificationToken, createActivityFeedItem);
    }
    else
    {
        console.log("No token for user, can not send notification.")
    }

    function sendNotification(androidNotificationToken, activityFeedItem)
    {
        let body;

        switch (activityFeedItem.type)
        {
            case "comment":
                body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                break;

            case "like":
                body = `${activityFeedItem.username} liked your post`;
                break;

            case "follow":
                body = `${activityFeedItem.username} started following you`;
                break;

            default:
            break;
        }

        const message =
        {
            notification: { body },
            token: androidNotificationToken,
            data: { recipient: userId },
        };

        admin.messaging().send(message)
        .then(response =>
        {
            console.log("Successfully sent message", response);
        })
        .catch(error =>
        {
            console.log("Error sending message", error);
        })

    }
});




exports.onCreateFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onCreate(async (snapshot, context) => {

    console.log("Follower Created", snapshot.id);

    const userId = context.params.userId;

    const followerId = context.params.followerId;

//    const incrementFollowers = admin
//                  .firestore()
//                  .collection("followers").doc(userId);
//
//            const newIncrementFollowers = incrementFollowers.data().countFollowers+1;
//
//            const incrementFollowings = admin
//                      .firestore()
//                      .collection("following").doc(followerId);
//            const newIncrementFollowings = incrementFollowings.data().countFollowings+1;
//            incrementFollowers.update({countFollowers: newIncrementFollowers});
//            incrementFollowings.update({countFollowings: newIncrementFollowings});

    //increment the number of followers
    //const increment = admin.firestore.FieldValue.increment(1);
    const batch = admin.firestore().batch();
    const incrementFollowers = admin
          .firestore()
          .collection("followers").doc(userId);
    const incrementFollowings = admin
              .firestore()
              .collection("following").doc(followerId);
    //incrementFollowers.update({countFollowers: admin.firestore.FieldValue.increment(1)});
    //incrementFollowings.update({countFollowings: admin.firestore.FieldValue.increment(1)});
//    const batch = firestore.batch();
    batch.update(incrementFollowers,{countFollowers: admin.firestore.FieldValue.increment(1)}, {merge: true});
    batch.update(incrementFollowings, {countFollowings: admin.firestore.FieldValue.increment(1)}, {merge: true});
    batch.commit();

    const followedUserPostsRef = admin
      .firestore()
      .collection("posts")
      .doc(userId)
      .collection("usersPosts");

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts");

    const querySnapshot = await followedUserPostsRef.get();

    querySnapshot.forEach(doc => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();
        timelinePostsRef.doc(postId).set(postData);
      }
    });
  });





  exports.onDeleteFollower = functions.firestore
  .document("/followers/{userId}/userFollowers/{followerId}")
  .onDelete(async (snapshot, context) => {

    console.log("Follower Deleted", snapshot.id);

    const userId = context.params.userId;

    const followerId = context.params.followerId;

    const batch = admin.firestore().batch();
                           const incrementFollowers = admin
                                     .firestore()
                                     .collection("followers").doc(userId);
                               const incrementFollowings = admin
                                         .firestore()
                                         .collection("following").doc(followerId);
                               //incrementFollowers.update({countFollowers: admin.firestore.FieldValue.increment(-1)});
                               //incrementFollowings.update({countFollowings: admin.firestore.FieldValue.increment(-1)});

                               batch.update(incrementFollowers,{countFollowers: admin.firestore.FieldValue.increment(-1)}, {merge: true});
                               batch.update(incrementFollowings, {countFollowings: admin.firestore.FieldValue.increment(-1)}, {merge: true});
                               batch.commit();

//        //const decrement = admin.firestore.FieldValue.increment(-1);
//        const incrementFollowers = admin
//              .firestore()
//              .collection("followers").doc(userId);
//
//        //const newIncrementFollowers = incrementFollowers.data().countFollowers-1;
//
//        const incrementFollowings = admin
//                  .firestore()
//                  .collection("following").doc(followerId);
//        //const newIncrementFollowings = incrementFollowings.data().countFollowings-1;
//        incrementFollowers.update({countFollowers: newIncrementFollowers});
//        incrementFollowings.update({countFollowings: newIncrementFollowings});
//        const batch = admin.firestore.batch();
//        batch.set(incrementFollowers,{countFollowers: admin.firestore.FieldValue.increment(-1)}, {merge: true});
//        batch.set(incrementFollowings, {countFollowings: admin.firestore.FieldValue.increment(-1)}, {merge: true});
//        batch.commit();

    const timelinePostsRef = admin
      .firestore()
      .collection("timeline")
      .doc(followerId)
      .collection("timelinePosts")
      .where("ownerId", "==", userId);

    const querySnapshot = await timelinePostsRef.get();
    querySnapshot.forEach(doc => {
      if (doc.exists)
      {
        doc.ref.delete();
      }
    });
  });

  exports.onCreateLike = functions.firestore
  .document("/posts/{userId}/usersPosts/{postId}/like/{likeId}")
  .onCreate(async(snapshot, context) => {
  const userId = context.params.userId;
   const postId = context.params.postId;
  const incrementLike = admin.firestore().collection("posts").doc(userId).collection("usersPosts").doc(postId);
  incrementLike.update({countLike: admin.firestore.FieldValue.increment(1)});
  });

  exports.onDeleteLike = functions.firestore
    .document("/posts/{userId}/usersPosts/{postId}/like/{likeId}")
    .onDelete(async(snapshot, context) => {
    const userId = context.params.userId;
     const postId = context.params.postId;
    const decrementLike = admin.firestore().collection("posts").doc(userId).collection("usersPosts").doc(postId);
    decrementLike.update({countLike: admin.firestore.FieldValue.increment(-1)});
    });

exports.onCreatePost = functions.firestore
  .document("/posts/{userId}/usersPosts/{postId}")
  .onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

   const incrementPosts = admin
             .firestore()
             .collection("posts").doc(userId);
    incrementPosts.update({countPosts: admin.firestore.FieldValue.increment(1)});


    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .set(postCreated);
    });
  });





//exports.onUpdatePost = functions.firestore
//  .document("/posts/{userId}/usersPosts/{postId}")
//  .onUpdate(async (change, context) => {
//    const postUpdated = change.after.data();
//    const userId = context.params.userId;
//    const postId = context.params.postId;
//
//    const userFollowersRef = admin
//      .firestore()
//      .collection("followers")
//      .doc(userId)
//      .collection("userFollowers");
//
//    const querySnapshot = await userFollowersRef.get();
//
//    querySnapshot.forEach(doc => {
//      const followerId = doc.id;
//
//      admin
//        .firestore()
//        .collection("timeline")
//        .doc(followerId)
//        .collection("timelinePosts")
//        .doc(postId)
//        .get()
//        .then(doc => {
//          if (doc.exists) {
//            doc.ref.update(postUpdated);
//          }
//        });
//    });
//  });





exports.onDeletePost = functions.firestore
  .document("/posts/{userId}/usersPosts/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    const decrementPosts = admin
                 .firestore()
                 .collection("posts").doc(userId);
     decrementPosts.update({countPosts: admin.firestore.FieldValue.increment(-1)});

    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();

    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.delete();
          }
        });
    });
  });