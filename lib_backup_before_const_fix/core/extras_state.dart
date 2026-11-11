import 'package:flutter/material.dart';

/// Small bits of customer state needed by the Edit profile / App settings
/// screens. Kept out of `app_state.dart` so existing state is untouched.
class ExtrasState extends ChangeNotifier {
  String emergencyContact = '';
  bool orderUpdatesOn = true;
  bool promosOn = false;
  bool biometricOn = true;
  String language = 'English';

  static const languages = ['English', 'Luganda', 'Kiswahili'];

  void changed() => notifyListeners();
}

final extras = ExtrasState();
