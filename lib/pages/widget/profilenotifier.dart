import 'package:flutter/material.dart';

class ProfileNotifier extends ValueNotifier<String?> {
  ProfileNotifier(super.value);

  void updateProfilePicture(String? newValue) {
    value = newValue;
  }
}
