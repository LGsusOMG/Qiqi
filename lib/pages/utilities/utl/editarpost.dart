import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarPostScreen extends StatefulWidget {
  final String userId;
  final int postIndex;
  final String initialDescription;

  const EditarPostScreen({
    super.key,
    required this.userId,
    required this.postIndex,
    required this.initialDescription,
  });

  @override
  _EditarPostScreenState createState() => _EditarPostScreenState();
}

class _EditarPostScreenState extends State<EditarPostScreen> {
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.userId).update({
        'descriptions.${widget.postIndex}': descriptionController.text,
      });
      Navigator.of(context).pop(); // Regresar a la pantalla anterior
    } catch (e) {
      print('Error al actualizar la publicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Publicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarCambios,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            hintText: 'Nueva descripción',
          ),
          maxLines: null, // Permite múltiples líneas
        ),
      ),
    );
  }
}
