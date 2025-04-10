import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xtats001/pages/utilities/login.dart'; // Importa la pantalla de login

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConfiguracionScreenState createState() => ConfiguracionScreenState();
}

class ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool isDarkMode = false;

  // obten el modo de tema actual guardado
  void getThemeMode() async {
    final savedThemeMode = await AdaptiveTheme.getThemeMode();
    if (savedThemeMode == AdaptiveThemeMode.dark) {
      setState(() {
        isDarkMode = true;
      });
    } else {
      setState(() {
        isDarkMode = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getThemeMode(); // al iniciar la pantalla, recupera el modo de tema actual
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // regresa a la pantalla anterior
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text("Editar perfil"),
              leading: const Icon(Icons.edit),
              onTap: () {
                Navigator.pushNamed(context, '/editarPerfil');
              },
            ),
            ListTile(
              title: const Text("Privacidad"),
              leading: const Icon(Icons.privacy_tip),
              onTap: () {
                Navigator.pushNamed(context, '/privacidad');
              },
            ),
            ListTile(
              title: const Text("Notificaciones"),
              leading: const Icon(Icons.notifications),
              onTap: () {
                Navigator.pushNamed(context, '/notificaciones');
              },
            ),
            ListTile(
              title: const Text("Ayuda"),
              leading: const Icon(Icons.help),
              onTap: () {
                Navigator.pushNamed(context, '/ayuda');
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text("Modo Claro/Oscuro"),
              secondary: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                child: Icon(
                  isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              ),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                if (value) {
                  AdaptiveTheme.of(context).setDark();
                } else {
                  AdaptiveTheme.of(context).setLight();
                }
              },
            ),
            const Divider(),
            ListTile(
              title: const Text("Cerrar sesión"),
              leading: const Icon(Icons.logout),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Has cerrado sesión")),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
