import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xtats001/pages/utilities/curved_navigation_bar.dart';
import 'package:xtats001/pantallas_principales/amigos.dart';
import 'package:xtats001/pantallas_principales/busq.dart';
import 'package:xtats001/pantallas_principales/home.dart';
import 'package:xtats001/pantallas_principales/perfil.dart';

class BarNav extends StatefulWidget {
  const BarNav({super.key});

  @override
  State<BarNav> createState() => _BarNavState();
}

class _BarNavState extends State<BarNav> {
  int currentTabIndex = 0;
  late List<Widget> pages;
  late Home homepage;
  late Amigos amigos;
  late Busq busqueda;
  //late Reels reels;
  late Perfil perfil;
  final PageController _pageController = PageController(); // Controlador para el PageView
  String? _profilePictureUrl;

  @override
  void initState() {
    homepage = const Home();
    amigos = const Amigos(userId: '',);
    busqueda = const Busq();
    //reels = const Reels();
    perfil = const Perfil();
    
    pages = [homepage, amigos, busqueda, perfil];

    _loadUserProfilePicture();
    super.initState();
  }

  Future<void> _loadUserProfilePicture() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _profilePictureUrl = userDoc['profilePicture'] ?? '';
          });
        }
      }
    } 
    catch (e) {
      print('Error cargando foto de perfil: $e');
    }
  }

  void _setSystemUIOverlayStyle({required bool darkMode}) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: darkMode ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness:
          darkMode ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    _setSystemUIOverlayStyle(darkMode: isDarkMode);

    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.transparent,
        color: isDarkMode ? Colors.grey[900]! : Colors.grey[200]!,
        buttonBackgroundColor: Colors.deepPurple,
        animationDuration: const Duration(milliseconds: 300),
        index: currentTabIndex,
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });

          _pageController.jumpToPage(index);
        },
        items: [
          Icon(Icons.home_outlined, color: isDarkMode ? Colors.white : Colors.black),
          Icon(Icons.group_outlined, color: isDarkMode ? Colors.white : Colors.black),
          Icon(Icons.search_outlined, color: isDarkMode ? Colors.white : Colors.black),
          //FaIcon(FontAwesomeIcons.circlePlay , color: isDarkMode ? Colors.white : Colors.black),
          _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 15,
                  backgroundImage: NetworkImage(_profilePictureUrl!),
                )
              : Icon(Icons.person_outlined, color: isDarkMode ? Colors.white : Colors.black),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            currentTabIndex = index; 
          });
        },
        children: pages, 
      ),
    );
  }
}
