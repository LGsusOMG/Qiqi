import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xtats001/pantallas_principales/barranav.dart';
import 'package:xtats001/pages/utilities/forgpass.dart';
import 'package:xtats001/pages/utilities/siginup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String email = "", password = "";
  final _formKey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();

  bool _obscureText = true;
  String emailError = "";
  String passwordError = "";

  Future<void> userLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const BarNav()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          emailError = 'Usuario no encontrado';
          passwordError = "";
        } else if (e.code == 'wrong-password') {
          passwordError = 'La contraseña es incorrecta';
          emailError = ""; 
        } else if (e.code == 'invalid-email') {
          emailError = 'Formato de correo no válido';
          passwordError = ""; 
        } else if (e.code == 'user-disabled') {
          emailError = 'Usuario deshabilitado. Contacta al soporte';
          passwordError = ""; 
        } else {
          emailError = "";
          passwordError = "El correo y la contraseña no coinciden. Por favor verifique sus datos"; 
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
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
                ])),
          ),
          Container(
            margin: EdgeInsets.only(top: MediaQuery.of(context).size.width / 1.7),
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
                        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 2,
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 36, 36, 36),
                            borderRadius: BorderRadius.circular(10)),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 30.0),
                              const Text(
                                "Inicio de sesión",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextFormField(
                                controller: useremailcontroller,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingrese su e-mail por favor';
                                  } else if (emailError.isNotEmpty) {
                                    return emailError; // Muestra el mensaje de error específico
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
                                  prefixIcon: Icon(Icons.mail),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    email = value;
                                    emailError = ""; // Limpia el mensaje de error al cambiar el input
                                  });
                                },
                              ),
                              const SizedBox(height: 30.0),
                              TextFormField(
                                controller: userpasswordcontroller,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingrese su contraseña por favor';
                                  } else if (passwordError.isNotEmpty) {
                                    return passwordError; // Muestra el mensaje de error específico
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
                                onChanged: (value) {
                                  setState(() {
                                    password = value;
                                    passwordError = ""; // Limpia el mensaje de error al cambiar el input
                                  });
                                },
                              ),
                              if (passwordError.isNotEmpty) ...[
                                const SizedBox(height: 5.0),
                                Text(
                                  passwordError,
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20.0),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen()));
                                },
                                child: Container(
                                    alignment: Alignment.topRight,
                                    child: const Text(
                                        "¿Olvidaste tu contraseña?",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20.0,
                                        ))),
                              ),
                              const SizedBox(height: 80.0),
                              GestureDetector(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    userLogin();
                                  }
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
                                      "Iniciar sesión",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Ubuntu'),
                                    )),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 70.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Siginup()));
                      },
                      child: const Text(
                        "¿No tienes una cuenta? Regístrate",
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
          ),
        ],
      ),
    );
  }
}
