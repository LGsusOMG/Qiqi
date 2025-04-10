import 'package:flutter/material.dart';

class Comunidades extends StatefulWidget {
  const Comunidades({super.key});

  @override
  State<Comunidades> createState() => _ComunidadesState();
}

class _ComunidadesState extends State<Comunidades> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Comunidades"),

      ),
    );
  }
}