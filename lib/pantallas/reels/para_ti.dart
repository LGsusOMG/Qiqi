import 'package:flutter/material.dart';

class ParaTi extends StatefulWidget {
  const ParaTi({super.key});

  @override
  State<ParaTi> createState() => _ParatiState();
}

class _ParatiState extends State<ParaTi> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Para Ti"),

      ),
    );
  }
}
