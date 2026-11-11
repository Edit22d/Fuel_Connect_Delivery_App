import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/core.dart';
import 'services/auth_service.dart';
import 'shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await auth.init();
  runApp(const FuelConnectApp());
}

class FuelConnectApp extends StatelessWidget {
  const FuelConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelConnect',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Keeps layouts intact on devices with very large system font sizes.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Shell(),
    );
  }
}
