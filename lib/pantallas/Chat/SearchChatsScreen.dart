import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas/Chat/chating.dart';

class SearchChatsScreen extends StatefulWidget {
  final String userId;

  const SearchChatsScreen({super.key, required this.userId});

  @override
  State<SearchChatsScreen> createState() => _SearchChatsScreenState();
}

class _SearchChatsScreenState extends State<SearchChatsScreen> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<String> chatIds = [];
  bool isSearching = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
    _fetchSuggestedChats();
  }

  // Función que se ejecuta cuando cambia el texto de la búsqueda
  void onSearchChanged(String value) {
    if (value.isNotEmpty) {
      setState(() {
        isSearching = true; // Modo búsqueda activado
      });
      _searchChats(value);
    } else {
      setState(() {
        isSearching = false; // Desactiva el modo búsqueda
        searchResults = []; // Limpia los resultados
      });
    }
  }

  // Buscar chats por nombre de usuario
  Future<void> _searchChats(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      // Filtrar chats existentes que coincidan con la búsqueda
      List<Map<String, dynamic>> filteredResults = [];

      for (String chatId in chatIds) {
        // Separar los IDs del chat
        List<String> ids = chatId.split('_');

        // Asegurarse de que haya dos partes en el ID
        if (ids.length != 2) continue;

        // Identificar el ID del otro usuario
        String otherUserId = ids.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        // Si el ID del otro usuario está vacío, omitir este chat
        if (otherUserId.isEmpty) continue;

        // Obtener información del otro usuario
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Comparar el nombre de usuario con la consulta
          final username = userData['username'] ?? 'Usuario desconocido';
          if (username.toLowerCase().contains(query.toLowerCase())) {
            filteredResults.add({
              'userId': otherUserId,
              'username': username,
              'profilePicture': userData['profilePicture'] ?? '',
            });
          }
        }
      }

      // Actualizar el estado con los resultados filtrados
      setState(() {
        searchResults = filteredResults;
      });
    } catch (e) {
      print("Error al buscar chats: $e");
    }
  }

  // Obtener los chats del usuario
  Future<void> _fetchSuggestedChats() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('chats')) {
          List<dynamic> chats = userData['chats'] ?? [];
          setState(() {
            chatIds = List<String>.from(chats);
          });
        } else {
          print("El campo 'chats' no existe en el documento del usuario.");
        }
      } else {
        print("El documento del usuario no existe.");
      }
    } catch (e) {
      print("Error al obtener los chats: $e");
    }
  }

  // Limpiar el controlador de búsqueda
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Buscar chats...',
            border: InputBorder.none,
          ),
          onChanged: onSearchChanged,
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Cerrar el teclado
        },
        child: isSearching
            ? ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final user = searchResults[index];
                  final String receiverId = user['userId'] ?? '';
                  final String receiverName = user['username'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['profilePicture'] != null
                          ? NetworkImage(user['profilePicture'])
                          : const AssetImage('images/logo.png')
                              as ImageProvider,
                    ),
                    title: Text(receiverName),
                    subtitle: const Text('Chat activo'),
                    onTap: () {
                      // Navegar a la pantalla de chat con el usuario seleccionado
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatingScreen(
                            receiverId:
                                receiverId, // ID del usuario con quien chatear
                            receiverName:
                                user['username'], // Nombre del usuario
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            : chatIds.isEmpty
                // Si no se tienen chats, mostrar mensaje informando al usuario
                ? const Center(child: Text('No tienes chats aún.'))
                : ListView.builder(
                    itemCount: chatIds.length, // Número de chats a mostrar
                    itemBuilder: (context, index) {
                      // Obtener el ID del chat actual
                      String chatId = chatIds[index];

                      // Separar los IDs de usuario para identificar al otro usuario en el chat
                      String otherUserId = chatId.split('_').firstWhere(
                            (id) => id != _auth.currentUser!.uid,
                            orElse: () => '',
                          );

                      // Si no se encuentra un ID válido, mostrar un mensaje de error
                      if (otherUserId.isEmpty) {
                        return const ListTile(
                          title: Text('Usuario desconocido'),
                        );
                      }

                      // Obtener los datos del otro usuario para mostrar en la lista de chats
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
                        builder: (context, userSnapshot) {
                          // Mostrar un indicador de carga mientras se espera la respuesta
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Center(child: CircularProgressIndicator()),
                            );
                          }

                          // Obtener los datos del usuario que participa en el chat
                          var userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;

                          // Mostrar la información del chat y permitir la navegación al chat
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  userData['profilePicture'] ?? ''),
                            ),
                            title: Text(userData['username']),
                            subtitle: const Text('Chat activo'),
                            onTap: () {
                              // Navegar a la pantalla de chat con el usuario seleccionado
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatingScreen(
                                    receiverId:
                                        otherUserId, // ID del usuario con quien chatear
                                    receiverName: userData[
                                        'username'], // Nombre del usuario
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
