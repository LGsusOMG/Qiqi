import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xtats001/pantallas/Perfil/Perfilusuario.dart';
import 'package:xtats001/pantallas/Perfil/perfilusuext.dart';

class ChatingScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatingScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ChatingScreenState createState() => ChatingScreenState();
}

class ChatingScreenState extends State<ChatingScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String chatId;
  String? receiverProfilePicture;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _getReceiverProfilePicture();
  }

  void _initializeChat() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      chatId = userId.hashCode <= widget.receiverId.hashCode
          ? '${userId}_${widget.receiverId}'
          : '${widget.receiverId}_$userId';

      _createChatForUser(currentUser.uid, widget.receiverId);
    }
  }

  Future<void> _createChatForUser(
      String currentUserId, String receiverId) async {
    final currentUserDoc =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final receiverUserDoc =
        FirebaseFirestore.instance.collection('users').doc(receiverId);

    try {
      await currentUserDoc.update({
        'chats': FieldValue.arrayUnion([chatId])
      });

      await receiverUserDoc.update({
        'chats': FieldValue.arrayUnion([chatId])
      });
    } catch (e) {
      print("Error al agregar chat a los usuarios: $e");
    }
  }

  Future<void> _getReceiverProfilePicture() async {
    try {
      DocumentSnapshot receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.receiverId)
          .get();
      setState(() {
        receiverProfilePicture = receiverDoc['profilePicture'];
      });
    } catch (e) {
      print("Error al obtener la foto de perfil del receptor: $e");
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && _controller.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': currentUser.uid,
          'receiverId': widget.receiverId,
          'messageText': _controller.text,
          'emojiReaction': '',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _controller.clear();
      } catch (e) {
        print("Error al enviar mensaje: $e");
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  Future<void> _editMessage(String messageId, String currentMessage) async {
    final newMessage = await _showEditDialog(currentMessage);
    if (newMessage != null && newMessage.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'messageText': newMessage});
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<String?> _showEditDialog(String currentMessage) async {
    TextEditingController editingController =
        TextEditingController(text: currentMessage);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edita tu mensaje'),
          content: TextField(
            controller: editingController,
            decoration: const InputDecoration(hintText: "Nuevo mensaje"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, editingController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageOptions(BuildContext context, String messageId,
      String messageText, bool isSender) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isSender)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar mensaje'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(messageId, messageText);
                },
              ),
            if (isSender)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar mensaje'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
            if (!isSender)
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Reaccionar con emoji'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiReactionDialog(messageId);
                },
              ),
          ],
        );
      },
    );
  }

  void _showEmojiReactionDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedEmoji = '';
        return AlertDialog(
          title: const Text('Selecciona un emoji para reaccionar'),
          content: SizedBox(
            height: 150,
            child: Column(
              children: <Widget>[
                TextField(
                  decoration:
                      const InputDecoration(hintText: "Escribe un emoji"),
                  onChanged: (value) {
                    selectedEmoji = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reaccionar'),
              onPressed: () async {
                if (selectedEmoji.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .doc(messageId)
                      .set({
                    'emojiReaction': selectedEmoji,
                  }, SetOptions(merge: true));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  right: 8.0), // Espacio entre foto y nombre
              child: GestureDetector(
                onTap: () {
                  // Verifica si el userId del receptor es igual al currentUserId
                  if (widget.receiverId == currentUserId) {
                    // Si es el usuario actual, navegar al perfil propio
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilUsu(userId: currentUserId),
                        // Reemplaza con la pantalla de perfil propia
                      ),
                    );
                  } else {
                    // Si no es el usuario actual, navegar al perfil del usuario externo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PerfilUsuarioScreen(userId: widget.receiverId),
                        // Reemplaza con la pantalla de perfil del receptor
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundImage: receiverProfilePicture != null
                      ? NetworkImage(receiverProfilePicture!)
                      : null,
                  child: receiverProfilePicture == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Verifica si el userId del receptor es igual al currentUserId
                if (widget.receiverId == currentUserId) {
                  // Si es el usuario actual, navegar al perfil propio
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PerfilUsu(userId: currentUserId),
                      // Reemplaza con la pantalla de perfil propia
                    ),
                  );
                } else {
                  // Si no es el usuario actual, navegar al perfil del usuario externo
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PerfilUsuarioScreen(userId: widget.receiverId),
                      // Reemplaza con la pantalla de perfil del receptor
                    ),
                  );
                }
              },
              child: Text(widget.receiverName),
            ),
          ],
        ),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context), // Regresar a la pantalla anterior
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : const Color.fromARGB(
                255, 142, 91, 231), // Color de la barra superior
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(216, 14, 13, 13).withOpacity(0.9)
              : const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay mensajes aún.'));
                  }
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final messageData = snapshot.data!.docs[index];
                      final bool isSender =
                          messageData['senderId'] == _auth.currentUser!.uid;
                      final String messageId = messageData.id;
                      final messageMap =
                          messageData.data() as Map<String, dynamic>;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: Align(
                          alignment: isSender
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSender
                                  ? Colors.deepPurpleAccent
                                  : const Color.fromARGB(255, 4, 135, 168),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: Offset(2, 2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7),
                            child: GestureDetector(
                              onLongPress: () => _showMessageOptions(
                                  context,
                                  messageId,
                                  messageData['messageText'],
                                  isSender),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    messageData['messageText'],
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  if (messageMap['emojiReaction'] != null &&
                                      messageMap['emojiReaction'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        messageMap['emojiReaction'],
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  if (messageData['timestamp'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text(
                                        _formatTimestamp(
                                            messageData['timestamp']),
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: isSender
                                                ? Colors.white70
                                                : Colors.black54),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                          color: Colors
                              .black), // Establecer el color del texto a negro
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        hintStyle: const TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide:
                              const BorderSide(color: Colors.blueAccent),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: Color.fromARGB(255, 124, 68, 255)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
