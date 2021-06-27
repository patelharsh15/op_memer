import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';



AppBar header(context, {bool isAppTitle=false, String strTitle, disappearedBackButton= false}) {
  if(strTitle == "Profile"){
    bool pro = true;
  }
  return AppBar(
    elevation: 0,

    brightness: Theme.of(context).brightness,
    iconTheme: IconThemeData(
      color: Theme.of(context).cardColor,
    ),
    automaticallyImplyLeading: disappearedBackButton ? false : true,
    title:
        Text(
          isAppTitle ? "op  Memer" : strTitle,
          style: TextStyle(
            color: Theme.of(context).cardColor,
            fontFamily: isAppTitle ? "Signatra" : "",
            fontSize: isAppTitle ? 45.0 : 22.0,

          ),
          overflow: TextOverflow.ellipsis,
    ),
    actions:
    [
      ChangeThemeButtonWidget(strTitle),
    ],
    centerTitle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,//accentColor
  );
}

class ChangeThemeButtonWidget extends StatelessWidget {
  String strTitle;
  ChangeThemeButtonWidget(this.strTitle);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if(strTitle == "Profile")
      {
        return Switch.adaptive(
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            final provider = Provider.of<ThemeProvider>(context, listen: false);
            provider.toggleTheme(value);
          },
        );
      }
    else{
      return Container(width: 0.0, height: 0.0);
    }
  }
}

