import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas/reels/busqueda.dart';
import 'package:xtats001/pantallas/reels/para_ti.dart';
import 'package:xtats001/pantallas/reels/siguiendo.dart';

class Reels extends StatefulWidget {
  const Reels({super.key});
  
  @override
  State<Reels> createState() => _ReelState();
}

class _ReelState extends State<Reels> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ParaTi(),  // Pantalla de para ti
    const Siguiendo(),   // Pantalla de siguiendo
    const Busqueda(),  // Pantalla de busqueda
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color.fromARGB(255, 128, 77, 218) : const Color.fromARGB(255, 149, 102, 230),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        TextButton(
          onPressed: () {
            setState(() {
          _selectedIndex = 1;
            });
          },
          child: Text(
            'Siguiendo',
            style: TextStyle(color: _selectedIndex == 1 ? Colors.blue : (isDarkMode ? Colors.white : Colors.black)),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
          _selectedIndex = 0;
            });
          },
          child: Text(
            'Para Ti',
            style: TextStyle(color: _selectedIndex == 0 ? Colors.blue : (isDarkMode ? Colors.white : Colors.black)),
          ),
        ),
          ],
        ),
        actions: [
         IconButton(
          icon: Icon(
            Icons.search,
              color: _selectedIndex == 2 ? Colors.blue : (isDarkMode ? Colors.white : Colors.black),
          ),
          onPressed: () {
            setState(() {
               _selectedIndex = 2;
            });
          },
        ),
        ],
      ),
    body: _screens[_selectedIndex],
    );
  }
}
