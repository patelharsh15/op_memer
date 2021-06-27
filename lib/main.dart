import 'package:buddiesgram/pages/HomePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //final followingRefrence = Firestore.instance.collection("following");
  FirebaseFirestore.instance.settings;
  //Firestore.instance.settings(timestampsInSnapshotsEnabled: true);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    //statusBarBrightness: Brightness.light ,
    //statusBarIconBrightness: Brightness.dark,
  ));

  //await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        builder: (context, _) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: 'op Memer',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            darkTheme: MyTheme.darkTheme,
            theme: MyTheme.lightTheme,
            home: HomePage(),
          );
        },
      );
}

class MyTheme {
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: Colors.black, //all background
    dialogBackgroundColor: Colors.black, //upload image dialog box, delete image
    primarySwatch: Colors.grey,
    accentColor: Colors.black,
    cardColor: Colors.white, //font color
    brightness: Brightness.dark,
  );
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white, //all background
    dialogBackgroundColor: Colors.white, //upload image dialog box, delete image
    primarySwatch: Colors.grey,
    accentColor: Colors.black,
    cardColor: Colors.black, //font color
    brightness: Brightness.light,
  );
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  bool get isDarkMode => themeMode == ThemeMode.dark;
  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

//"npm --prefix \"$RESOURCE_DIR\" run lint"
