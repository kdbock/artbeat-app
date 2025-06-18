import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'seed_data_uploader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await uploadSeedData();
}
