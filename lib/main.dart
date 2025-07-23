import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/onenote_service.dart';
import 'services/ollama_service.dart' as ollama;
import 'services/excel_service.dart' as excel;
import 'theme/app_theme.dart';

void main() {
  // Ensure proper cleanup on app exit
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late OneNoteService _oneNoteService;
  late ollama.OllamaService _ollamaService;
  late excel.ExcelService _excelService;

  @override
  void initState() {
    super.initState();
    _oneNoteService = OneNoteService();
    _ollamaService = ollama.OllamaService();
    _excelService = excel.ExcelService();
  }

  @override
  void dispose() {
    // Properly dispose all services
    _oneNoteService.dispose();
    _ollamaService.dispose();
    _excelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<OneNoteService>.value(value: _oneNoteService),
        Provider<ollama.OllamaService>.value(value: _ollamaService),
        Provider<excel.ExcelService>.value(value: _excelService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'OneNote to Excel Converter',
            theme: themeProvider.currentTheme,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
