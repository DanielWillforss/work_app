import 'package:app_core_widget/theme.dart';
import 'package:flutter/material.dart';
import 'pages/log_hours_page.dart';

void main() {
  //NotesApi.baseUrl = 'https://danielwillforss.site/work_app/notes/';
  //NotesApi.baseUrl = 'http://127.0.0.1:5000/work_app/';
  runApp(MyApp());
}

class GlobalConstants {
  //static const String baseUrl = 'https://danielwillforss.site/work_app';
  //static const String baseUrl = 'http://192.168.0.130/work_app';
  static const String baseUrl = 'http://localhost:3000';
  static const String version = '1.1.0';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work App',
      theme: RedTheme.appTheme,
      home: LogHoursPage(),

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }
}
