import 'dart:async';
import 'package:buddiesgram/widgets/HeaderWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();

  String username = " ";

  submitUsername(){
    final form = _formKey.currentState;
    if(form.validate()){
      form.save();

      SnackBar snackBar = SnackBar(content: Text("Welcome "+ username));

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Timer(Duration(seconds: 3), (){
        Navigator.pop(context, username);
      });
    }
  }

  bool ans=false;
  Future<bool> checkUsernameIsUnique(String username)
   async {
    QuerySnapshot querySnapshot;

    querySnapshot= await FirebaseFirestore.instance.collection("username").where("username",isEqualTo: username).get();

    if(querySnapshot.docs.isNotEmpty)
      {
        setState(() {
          ans = true;
        });
      }
    else{
      setState(() {
        ans = false;
      });
    }
    return querySnapshot.docs.isEmpty;
  }




  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, strTitle: "Set up your profile", disappearedBackButton: true),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[

                Padding(
                  padding: EdgeInsets.only(top: 26.0),
                  child: Center(
                    child: Text("Set up a username", style: TextStyle(fontSize: 26.0),),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(17.0),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: TextFormField(
                        style: TextStyle(color: Colors.white),
                        validator: (val) {
                          checkUsernameIsUnique(val);
                          if(val.isEmpty){
                            return "User name cannot be empty";
                          }
                          else if(val.trim().length>15){
                            return "User name is should be smaller than 15 characters.";
                          }
                          // ignore: unrelated_type_equality_checks
                          else if(ans)
                            {
                              return "Username is already taken";
                            }
                          else{
                            return null;
                          }
                        },
                        onSaved: (val) => username = val,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          border: OutlineInputBorder(),
                          labelText: "Username",
                          labelStyle: TextStyle(fontSize: 16.0),
                          hintText: "Must not be greater than 15 characters",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submitUsername,
                  child: Container(
                    height: 55.0,
                    width: 360.0,
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        "Proceed",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
