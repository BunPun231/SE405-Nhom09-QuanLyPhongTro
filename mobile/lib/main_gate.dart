import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/face_recognition_service.dart';
import 'presentation/screens/manager/gate_access_scan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait orientation for kiosk
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Hide status bar for fullscreen kiosk mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Initialize face recognition service
  await FaceRecognitionService.initialize();
  await FaceRecognitionService.preloadFaces();
  
  runApp(const GateKioskApp());
}

class GateKioskApp extends StatelessWidget {
  const GateKioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gate Access Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      home: const GateAccessScanScreen(kioskMode: true),
    );
  }
}
