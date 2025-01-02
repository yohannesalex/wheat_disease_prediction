import 'package:face_recognition/welcome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WelcomePage(),
    routes: {
      '/home': (context) => WheatRustDetection(),
    },
  ));
}
