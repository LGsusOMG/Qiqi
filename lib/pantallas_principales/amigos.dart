import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas/Chat/SearchChatsScreen.dart';
import 'package:xtats001/pantallas/Chat/chatscreen.dart';
import 'package:xtats001/pantallas/Chat/comunidades.dart';
import 'package:xtats001/pantallas/Chat/grupos.dart';


class Amigos extends StatefulWidget {
  final String userId; // Añadimos userId para el usuario autenticado

  const Amigos({super.key, required this.userId});

  @override
  State<Amigos> createState() => _AmigosState();
}

class _AmigosState extends State<Amigos> {
  final int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ChatsScreen(), // Cambié a ChatsScreen para que muestre la pantalla de chats
      const Grupos(), // Asegúrate de que esta clase exista
      const Comunidades(), // Asegúrate de que esta clase exista
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.deepPurple : const Color.fromARGB(255, 137, 91, 216),
        title: Text('Chats', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchChatsScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
    );
  }
}

