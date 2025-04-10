import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importa Firebase Storage
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas_principales/barranav.dart';
import 'package:xtats001/pages/utilities/login.dart';

class Siginup extends StatefulWidget {
  const Siginup({super.key});

  @override
  State<Siginup> createState() => _SiginupState();
}

class _SiginupState extends State<Siginup> {
  String email = "", password = "", user = "";

  TextEditingController usercontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  bool _obscureText = true;

  // Función para obtener la URL de la imagen por defecto
  Future<String> getDefaultProfilePictureUrl() async {
    try {
      // Obtén la URL de la imagen desde Firebase Storage
      String url = await FirebaseStorage.instance
          .ref('default/logo.png') // Ruta en Firebase Storage
          .getDownloadURL();
      return url;
    } catch (e) {
      print('Error obteniendo la URL de la imagen por defecto: $e');
      return '';
    }
  }

  registration() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String defaultProfilePictureUrl = await getDefaultProfilePictureUrl();

      // Guardar los datos en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'username': user,
        'email': email,
        'uid': userCredential.user!.uid,
        'createdAt':
            Timestamp.now(), // Agrega un campo con la fecha de creación
        'description': '', // Descripción del usuario
        'nickname': '', // Apodo del usuario
        'profilePicture':
            defaultProfilePictureUrl, // URL de la foto de perfil por defecto
        'isOnline': false, // Estado de conexión
        'lastActive': Timestamp.now(), // Última actividad
        'followers': [], // Lista de seguidores
        'following': [], // Lista de seguidos
        'friendRequests': [], // Lista de solicitudes de amistad
        'posts': [], // Lista de publicaciones
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Registro exitoso", style: TextStyle(fontSize: 20.0))));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const BarNav()));
    } on FirebaseException catch (e) {
      if (e.code == "weak-password") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text("Esta contraseña es muy débil",
                style: TextStyle(fontSize: 18.0))));
      } else if (e.code == "email-already-in-use") {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text("Este correo ya está en uso",
                style: TextStyle(fontSize: 18.0))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                      Color.fromARGB(255, 255, 255, 255),
                      Color.fromARGB(255, 255, 255, 255),
                    ]))),
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.width / 1.7),
              height: MediaQuery.of(context).size.height / 1,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 36, 36, 36),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50))),
              child: const Text(" "),
            ),
            SingleChildScrollView(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 1.0),
                  child: Column(
                    children: [
                      Center(
                          child: Image.asset(
                        "images/logo.png",
                        width: MediaQuery.of(context).size.width / 2,
                        height: MediaQuery.of(context).size.height / 3.4,
                        fit: BoxFit.scaleDown,
                      )),
                      Material(
                        elevation: 10.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 2,
                          decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 36, 36, 36),
                              borderRadius: BorderRadius.circular(10)),
                          child: Form(
                            key: _formkey,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 30.0,
                                ),
                                const Text(
                                  "Registro",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextFormField(
                                  controller: usercontroller,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese un nombre';
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.deepPurple,
                                  decoration: const InputDecoration(
                                      hintText: 'Usuario',
                                      hintStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                      ),
                                      prefixIcon: Icon(Icons.person)),
                                ),
                                const SizedBox(
                                  height: 30.0,
                                ),
                                TextFormField(
                                  controller: emailcontroller,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese un E-mail';
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.deepPurple,
                                  decoration: const InputDecoration(
                                      hintText: 'E-mail',
                                      hintStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                      ),
                                      prefixIcon: Icon(Icons.mail)),
                                ),
                                const SizedBox(
                                  height: 30.0,
                                ),
                                TextFormField(
                                  controller: passwordcontroller,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese una contraseña';
                                    }
                                    return null;
                                  },
                                  obscureText: _obscureText,
                                  cursorColor: Colors.deepPurple,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    hintStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20.0,
                                    ),
                                    prefixIcon: const Icon(Icons.key),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureText = !_obscureText;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20.0,
                                ),
                                const SizedBox(
                                  height: 80.0,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    if (_formkey.currentState!.validate()) {
                                      setState(() {
                                        email = emailcontroller.text;
                                        user = usercontroller.text;
                                        password = passwordcontroller.text;
                                      });
                                    }
                                    registration();
                                  },
                                  child: Material(
                                    elevation: 10.0,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      width: 200,
                                      decoration: BoxDecoration(
                                          color: Colors.deepPurple,
                                          borderRadius:
                                              BorderRadius.circular(30)),
                                      child: const Center(
                                          child: Text(
                                        "Registrarse",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins1'),
                                      )),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 70.0,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()));
                        },
                        child: const Text(
                          "¿Ya tienes una cuenta? Inicia sesión",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins1'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
