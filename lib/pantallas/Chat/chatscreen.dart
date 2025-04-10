import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas/Chat/chating.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  ChatsScreenState createState() => ChatsScreenState();
}

class ChatsScreenState extends State<ChatsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> chatIds = [];

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        // Obtener el documento del usuario autenticado
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        // Verificar si el documento existe y contiene datos
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Verificar si el campo 'chats' existe
          if (userData.containsKey('chats')) {
            List<dynamic> chats = userData['chats'] ?? [];
            print("Chats obtenidos: $chats"); // Debugging
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: chatIds.isEmpty
          ? const Center(child: Text('No tienes chats aún.'))
          : ListView.builder(
              itemCount: chatIds.length,
              itemBuilder: (context, index) {
                // Obtener el ID del chat actual
                String chatId = chatIds[index];

                // Separar los IDs de usuario
                String otherUserId = chatId.split('_').firstWhere(
                      (id) => id != _auth.currentUser!.uid,
                      orElse: () => '',
                    );

                if (otherUserId.isEmpty) {
                  return const ListTile(
                    title: Text('Usuario desconocido'),
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        title: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Obtener datos del otro usuario
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(userData['profilePicture'] ?? ''),
                      ),
                      title: Text(userData['username']),
                      subtitle: const Text('Chat activo'),
                      onTap: () {
                        // Navegar a la pantalla de chat
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatingScreen(
                              receiverId: otherUserId,
                              receiverName: userData['username'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
