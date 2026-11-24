import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // URL limpia (sin '#') cuando la app corre en el navegador web.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: TutorAdaptativoApp()));
}
