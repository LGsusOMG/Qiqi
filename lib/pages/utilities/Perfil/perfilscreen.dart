import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class PerfilScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PerfilScreen({super.key, required this.userId, required this.userData});

  @override
  PerfilScreenState createState() => PerfilScreenState();
}

class PerfilScreenState extends State<PerfilScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _imageUrl;
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.userData['username'] ?? '';
    _nicknameController.text = widget.userData['nickname'] ?? '';
    _descriptionController.text = widget.userData['description'] ?? '';
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      try {
        await ref.putFile(File(_imageFile!.path));
        final url = await ref.getDownloadURL();
        setState(() {
          _imageUrl = url;
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'profilePicture': url});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Imagen actualizada con éxito'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al actualizar la imagen'),
        ));
      }
    }
  }

  Future<void> _updateProfile() async {
    final updatedData = {
      'username': _usernameController.text,
      'nickname': _nicknameController.text,
      'description': _descriptionController.text,
    };

    if (_imageUrl != null) {
      updatedData['profilePicture'] = _imageUrl!;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado con éxito'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al actualizar el perfil'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar perfil'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: _imageFile != null
                    ? Image.file(File(_imageFile!.path), height: 300, width: 300) 
                    : widget.userData['profilePicture'] != ''
                        ? Image.network(widget.userData['profilePicture'],
                            height: 300, width: 300)
                        : Image.asset('images/logo.png', height: 300, width: 300), 
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Seleccionar imagen'),
                    ),
                  ),
                  const SizedBox(width: 10), 
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _uploadImage,
                      child: const Text('Actualizar imagen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Apodo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
