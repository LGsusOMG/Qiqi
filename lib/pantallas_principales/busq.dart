import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas/Perfil/Perfilusuario.dart';
import 'package:xtats001/pantallas/Perfil/perfilusuext.dart';

class Busq extends StatefulWidget {
  const Busq({super.key});

  @override
  State<Busq> createState() => _BusqState();
}

class _BusqState extends State<Busq> {
  TextEditingController searchController =
      TextEditingController(); // Controlador para el campo de búsqueda
  List<Map<String, dynamic>> searchResults =
      []; // Lista para almacenar los resultados de la búsqueda
  List<Map<String, dynamic>> suggestedUsers =
      []; // Lista para usuarios sugeridos (muestra aleatoriamente)
  bool isSearching = false; // Bandera para verificar si se está buscando

  @override
  void initState() {
    super.initState();
    _fetchSuggestedUsers(); // Cargar sugerencias al inicio
  }

  // Función que se ejecuta cuando cambia el texto de la búsqueda
  void onSearchChanged(String value) {
    if (value.isNotEmpty) {
      setState(() {
        isSearching = true; // Indica que está en modo búsqueda
      });
      searchUsers(value); // Realiza la búsqueda
    } else {
      setState(() {
        isSearching = false; // Si no hay texto, detiene la búsqueda
        searchResults = []; // Limpia los resultados
      });
    }
  }

  // Realiza la búsqueda en Firestore de usuarios que coincidan con la consulta
  Future<void> searchUsers(String query) async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username',
              isGreaterThanOrEqualTo:
                  query) // Filtra por coincidencia con el inicio del nombre de usuario
          .where('username',
              isLessThanOrEqualTo:
                  '$query\uf8ff') // Asegura que la búsqueda sea exacta
          .get();

      setState(() {
        // Mapea los resultados de la búsqueda a una lista de mapas
        searchResults = userSnapshot.docs.map((doc) {
          return {
            'userId': doc.id,
            'username': doc['username'] ?? '',
            'profilePicture': doc['profilePicture'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print("Error al buscar usuarios: $e");
    }
  }

  // Función para obtener usuarios sugeridos (una lista aleatoria de usuarios)
  Future<void> _fetchSuggestedUsers() async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(5) // Limita el número de usuarios sugeridos
          .get();

      setState(() {
        // Mapea los usuarios sugeridos a la lista
        suggestedUsers = userSnapshot.docs.map((doc) {
          return {
            'userId': doc.id,
            'username': doc['username'] ?? '',
            'profilePicture': doc['profilePicture'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print("Error al obtener usuarios sugeridos: $e");
    }
  }

  @override
  void dispose() {
    searchController
        .dispose(); // Libera el controlador cuando el widget se destruye
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar usuarios...',
            border: InputBorder.none,
          ),
          onChanged:
              onSearchChanged, // Llama a la función cuando cambia el texto
        ),
        backgroundColor: const Color.fromARGB(
            255, 137, 87, 224), // Color personalizado de la app bar
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context)
              .unfocus(); // Cierra el teclado cuando se toca fuera del campo de texto
        },
        child: isSearching
            ? ListView.builder(
                itemCount: searchResults
                    .length, // Muestra los resultados de la búsqueda
                itemBuilder: (context, index) {
                  final user = searchResults[index];
                  final String userId = user['userId'] ?? '';
                  final String username =
                      user['username'] ?? 'Usuario desconocido';
                  final String profilePicture = user['profilePicture'] ?? '';

                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  return ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        // Verifica si el userId del post es igual al currentUserId
                        if (userId == currentUserId) {
                          // Si es el usuario actual, navegar al perfil propio
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PerfilUsu(userId: user['userId']),
                              // Tu pantalla de perfil
                            ),
                          );
                        } else {
                          // Si no es el usuario actual, navegar al perfil del usuario externo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PerfilUsuarioScreen(userId: user['userId']),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: profilePicture.isNotEmpty
                            ? NetworkImage(user['profilePicture'])
                            : const AssetImage('images/logo.png')
                                as ImageProvider,
                      ),
                    ),
                    title: GestureDetector(
                      onTap: () {
                        // Verifica si el userId del post es igual al currentUserId
                        if (userId == currentUserId) {
                          // Si es el usuario actual, navegar al perfil propio
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Tu pantalla de perfil
                              builder: (context) => PerfilUsu(
                                userId: user['userId'],
                              ),
                            ),
                          );
                        } else {
                          // Si no es el usuario actual, navegar al perfil del usuario externo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PerfilUsuarioScreen(userId: user['userId']),
                            ),
                          );
                        }
                      },
                      child: Text(username),
                    ),
                  );
                },
              )
            : ListView.builder(
                itemCount:
                    suggestedUsers.length, // Muestra los usuarios sugeridos
                itemBuilder: (context, index) {
                  final user = suggestedUsers[index];
                  final String userId = user['userId'] ?? '';
                  final String username =
                      user['username'] ?? 'Usuario desconocido';
                  final String profilePicture = user['profilePicture'] ?? '';

                  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                  return ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        // Verifica si el userId del post es igual al currentUserId
                        if (userId == currentUserId) {
                          // Si es el usuario actual, navegar al perfil propio
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PerfilUsu(userId: user['userId']),
                              // Tu pantalla de perfil
                            ),
                          );
                        } else {
                          // Si no es el usuario actual, navegar al perfil del usuario externo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PerfilUsuarioScreen(userId: user['userId']),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: profilePicture.isNotEmpty
                            ? NetworkImage(user['profilePicture'])
                            : const AssetImage('images/logo.png')
                                as ImageProvider,
                      ),
                    ),
                    title: GestureDetector(
                      onTap: () {
                        // Verifica si el userId del post es igual al currentUserId
                        if (userId == currentUserId) {
                          // Si es el usuario actual, navegar al perfil propio
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Tu pantalla de perfil
                              builder: (context) => PerfilUsu(
                                userId: user['userId'],
                              ),
                            ),
                          );
                        } else {
                          // Si no es el usuario actual, navegar al perfil del usuario externo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PerfilUsuarioScreen(userId: user['userId']),
                            ),
                          );
                        }
                      },
                      child: Text(username),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
