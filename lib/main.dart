import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sala_pose_detection/feature/home/presentation/screen/home_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Left-side Landscape
    DeviceOrientation.portraitDown, // Right-side Landscape
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName:(_)=>HomeScreen()
      },
    );
  }
}

