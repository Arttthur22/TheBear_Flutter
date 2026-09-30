import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/login_page.dart';
import 'services/banco_service.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/pedido_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final banco = BancoService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel(banco)),
        ChangeNotifierProvider(create: (_) => PedidoViewModel(banco)),
      ],
      child: const TheBearApp(),
    ),
  );
}

class TheBearApp extends StatelessWidget {
  const TheBearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Bear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade800),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
