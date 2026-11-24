import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preferencia de tema (claro, oscuro o el del sistema).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
