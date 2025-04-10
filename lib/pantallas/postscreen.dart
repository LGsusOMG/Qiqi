import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  State createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _mediaFiles;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();

  Future<void> _selectMedia() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles == null || pickedFiles.isEmpty) return;

    setState(() {
      _mediaFiles = pickedFiles;
    });
  }

  Future<void> _publishPost() async {
    if (_mediaFiles == null || _mediaFiles!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona imágenes")),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      Timestamp timestamp = Timestamp.now();
      List<String> imageUrl = [];

      // Sube los archivos a Firebase Storage y guarda las URLs.
      for (var file in _mediaFiles!) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('posts')
              .child('${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}');
          await ref.putFile(File(file.path));
          final mediaUrl = await ref.getDownloadURL();
          imageUrl.add(mediaUrl);
        } catch (e) {
          print("Error al subir el archivo: $e");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al subir el archivo: ${file.path}'),
          ));
        }
      }

      // Crear el mapa de datos de la publicación.
      Map<String, dynamic> postData = {
        'userId': userId,
        'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : '',
        'hashtags': _hashtagsController.text.isNotEmpty ? _hashtagsController.text.split(' ') : [],
        'timestamp': timestamp,
        'favorites': {
          'count': 0,
          'users': []
        },
        'likes': {
          'count': 0,
          'users': []
        },
        'comments': {
          'count': 0,
          'data': {}
        },
        'shares': {
          'count': 0,
          'users': []
        },
        'imageUrl': imageUrl,
      };

      // se agrega la publicación a Firestore y obtiene el ID.
      DocumentReference postRef = await FirebaseFirestore.instance.collection('posts').add(postData);
      String postId = postRef.id; // Obtiene el ID de la publicación recién creada.

      // actualiza el documento del usuario con el ID de la publicación.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'publicaciones': FieldValue.arrayUnion([postId]), // guarda el ID en lugar de la URL.
        'postTimestamps': FieldValue.arrayUnion([timestamp]),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Publicación realizada con éxito'),
      ));
      Navigator.pop(context);
    } catch (e) {
      print("Error al publicar: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al publicar: $e'),
      ));
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Publicación"),
        actions: [
          TextButton(
            onPressed: _publishPost,
            child: const Text("Publicar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(1.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _selectMedia,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * 0.5,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _mediaFiles == null || _mediaFiles!.isEmpty
                        ? const Center(child: Text("Toca aquí para seleccionar imágenes"))
                        : SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: PageView.builder(
                              itemCount: _mediaFiles!.length,
                              itemBuilder: (context, index) {
                                final file = _mediaFiles![index];
                                return Image.file(File(file.path));
                              },
                            ),
                          ),
                  ),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(hintText: "Descripción"),
                ),
                TextField(
                  controller: _hashtagsController,
                  decoration: const InputDecoration(hintText: "Hashtags"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
