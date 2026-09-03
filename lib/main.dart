import 'dart:io';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'services/api_http.dart';

void main() {
  HttpOverrides.global = ApiHttpOverrides();
  runApp(const App());
}
