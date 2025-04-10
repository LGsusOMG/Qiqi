import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}



class _SettingsState extends State<Settings> {
  bool isDarkMode=false;
void getThemeMode () async{
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  if (savedThemeMode==AdaptiveThemeMode.dark){
    setState(() {
      isDarkMode=true;
    });
  } else {
    setState(() {
      isDarkMode=false;
    });
  }
}
  @override
  void initState() {
    getThemeMode();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child:  SwitchListTile(title: const Text("Light/Dark"),
          secondary: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:  isDarkMode ? Colors.white: Colors.black,
            ),
            child: Icon(
              isDarkMode ? Icons.nightlight_round: Icons.wb_sunny_rounded,
              color: isDarkMode? Colors.black: Colors.white,
            ),
          ),
            value: isDarkMode, onChanged: (value){
            setState(() {
              isDarkMode=value;
            });
            if (value){
              AdaptiveTheme.of(context).setDark();
            }
            else {
              AdaptiveTheme.of(context).setLight();
            }
          }),
        ),

      ),
    );
  }
}