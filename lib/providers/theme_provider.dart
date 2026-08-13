import 'package:flutter/material.dart';
class ThemeProvider extends ChangeNotifier { ThemeMode mode = ThemeMode.system; void setMode(ThemeMode value) { mode=value; notifyListeners(); } }
