import 'package:flutter/material.dart';

class AppWidget{
static TextStyle boldTextFeildStyle(){
  // ignore: prefer_const_constructors
  return  TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu');
}

static TextStyle HeadLineTextFeildStyle(){
  // ignore: prefer_const_constructors
  return  TextStyle(
                  color: Colors.black,
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu');
}

static TextStyle LightTextFeildStyle(){
  // ignore: prefer_const_constructors
  return  TextStyle(
                  color: Colors.black38,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Ubuntu');
}

}