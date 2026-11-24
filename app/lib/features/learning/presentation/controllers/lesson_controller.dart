import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../adaptive_engine/domain/adaptive_calculator.dart';
import '../../../adaptive_engine/domain/services/adaptive_engine.dart';
import '../../domain/entities/ejercicio.dart';
import '../../domain/entities/intento_ejercicio.dart';
import '../../domain/entities/leccion.dart';
import '../../domain/models/resumen_leccion.dart';
import '../../domain/repositories/learning_repository.dart';
import '../../domain/services/gamification_rules.dart';

/// Identifica una sesión de lección para una familia de providers.
@immutable
class LessonRequest {
  const LessonRequest({
    required this.usuarioId,
    required this.moduloId,
    required this.leccionId,
  });

  final int usuarioId;
  final int moduloId;
  final int leccionId;

  @override
  bool operator ==(Object other) {
    return other is LessonRequest &&
        other.usuarioId == usuarioId &&
        other.moduloId == moduloId &&
        other.leccionId == leccionId;
  }

  @override
  int get hashCode => Object.hash(usuarioId, moduloId, leccionId);
}

/// Estado inmutable de la pantalla de lección.
class LessonState {
  const LessonState({
    this.isLoading = false,
    this.error,
    this.leccion,
    this.ejercicioActual,
    this.totalEjercicios = 0,
    this.respondidos = 0,
    this.correctos = 0,
    this.vidas = AppConfig.vidasPorLeccion,
    this.opcionSeleccionada,
    this.respuestaVerificada = false,
    this.esCorrecta,
    this.xpSesion = 0,
    this.dominioActual = AdaptiveCalculator.initialMastery,
    this.dificultadObjetivo = 1,
    this.erroresConsecutivos = 0,
    this.refuerzoActivo = false,
    this.intentos = const <IntentoEjercicio>[],
    this.dominioAntes = AdaptiveCalculator.initialMastery,
    this.dificultadAntes = 1,
    this.resumen,
    this.ultimaDecision,
  });

  const LessonState.loading() : this(isLoading: true);

  const LessonState.error(String message) : this(error: message);

  final bool isLoading;
  final String? error;
  final Leccion? leccion;
  final Ejercicio? ejercicioActual;
  final int totalEjercicios;
  final int respondidos;
  final int correctos;
  final int vidas;
  final int? opcionSeleccionada;
  final bool respuestaVerificada;
  final bool? esCorrecta;
  final int xpSesion;
  final double dominioActual;
  final int dificultadObjetivo;
  final int erroresConsecutivos;
  final bool refuerzoActivo;
  final List<IntentoEjercicio> intentos;
  final double dominioAntes;
  final int dificultadAntes;
  final ResumenLeccion? resumen;
  final AdaptiveDecision? ultimaDecision;

  bool get finalizado => resumen != null;

  bool get sinVidas => vidas <= 0;

  bool get puedeComprobar =>
      !isLoading &&
      error == null &&
      ejercicioActual != null &&
      opcionSeleccionada != null &&
      !respuestaVerificada;

  bool get esUltimoEjercicio => respondidos >= totalEjercicios;

  double get progreso {
    if (totalEjercicios == 0) return 0;
    return (respondidos / totalEjercicios).clamp(0.0, 1.0).toDouble();
  }

  double get precision {
    if (respondidos == 0) return 0;
    return correctos / respondidos;
  }

  static const Object _unset = Object();

  LessonState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Leccion? leccion,
    Object? ejercicioActual = _unset,
    int? totalEjercicios,
    int? respondidos,
    int? correctos,
    int? vidas,
    Object? opcionSeleccionada = _unset,
    bool? respuestaVerificada,
    Object? esCorrecta = _unset,
    int? xpSesion,
    double? dominioActual,
    int? dificultadObjetivo,
    int? erroresConsecutivos,
    bool? refuerzoActivo,
    List<IntentoEjercicio>? intentos,
    double? dominioAntes,
    int? dificultadAntes,
    Object? resumen = _unset,
    Object? ultimaDecision = _unset,
  }) {
    return LessonState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      leccion: leccion ?? this.leccion,
      ejercicioActual: identical(ejercicioActual, _unset)
          ? this.ejercicioActual
          : ejercicioActual as Ejercicio?,
      totalEjercicios: totalEjercicios ?? this.totalEjercicios,
      respondidos: respondidos ?? this.respondidos,
      correctos: correctos ?? this.correctos,
      vidas: vidas ?? this.vidas,
      opcionSeleccionada: identical(opcionSeleccionada, _unset)
          ? this.opcionSeleccionada
          : opcionSeleccionada as int?,
      respuestaVerificada: respuestaVerificada ?? this.respuestaVerificada,
      esCorrecta: identical(esCorrecta, _unset)
          ? this.esCorrecta
          : esCorrecta as bool?,
      xpSesion: xpSesion ?? this.xpSesion,
      dominioActual: dominioActual ?? this.dominioActual,
      dificultadObjetivo: dificultadObjetivo ?? this.dificultadObjetivo,
      erroresConsecutivos: erroresConsecutivos ?? this.erroresConsecutivos,
      refuerzoActivo: refuerzoActivo ?? this.refuerzoActivo,
      intentos: intentos ?? this.intentos,
      dominioAntes: dominioAntes ?? this.dominioAntes,
      dificultadAntes: dificultadAntes ?? this.dificultadAntes,
      resumen: identical(resumen, _unset)
          ? this.resumen
          : resumen as ResumenLeccion?,
      ultimaDecision: identical(ultimaDecision, _unset)
          ? this.ultimaDecision
          : ultimaDecision as AdaptiveDecision?,
    );
  }
}

/// Orquesta la sesión: carga, evaluación adaptativa, intentos y cierre.
class LessonController extends StateNotifier<LessonState> {
  LessonController({
    required LearningRepository repository,
    required LessonRequest request,
    VoidCallback? onDataChanged,
  })  : _repository = repository,
        _request = request,
        _onDataChanged = onDataChanged,
        super(const LessonState.loading()) {
    _initialize();
  }

  final LearningRepository _repository;
  final LessonRequest _request;
  final VoidCallback? _onDataChanged;
  final AdaptiveEngine _engine = const AdaptiveEngine();
  final Stopwatch _stopwatch = Stopwatch();
  final List<Ejercicio> _pendientes = <Ejercicio>[];

  late Leccion _leccion;

  Future<void> _initialize() async {
    try {
      final leccion = await _repository.obtenerLeccion(_request.leccionId);
      final ejercicios =
          await _repository.obtenerEjercicios(_request.leccionId);
      final progreso = await _repository.obtenerProgreso(
        _request.usuarioId,
        _request.moduloId,
      );

      if (!mounted) return;

      if (ejercicios.isEmpty) {
        state = const LessonState.error(
          'Esta lección todavía no tiene ejercicios disponibles.',
        );
        return;
      }

      final baseDifficulty =
          AdaptiveCalculator.difficultyForMastery(progreso.nivelDominio);
      final needsReinforcement = progreso.rachaErroresConsecutivos >=
          AdaptiveCalculator.reinforcementThreshold;
      final targetDifficulty = needsReinforcement
          ? AdaptiveCalculator.clampDifficulty(baseDifficulty - 1)
          : baseDifficulty;

      _leccion = leccion;
      _pendientes
        ..clear()
        ..addAll(ejercicios);

      final primero = _engine.selectNextExercise(
        remaining: _pendientes,
        targetDifficulty: targetDifficulty,
        reinforcement: needsReinforcement,
      );
      _pendientes.remove(primero);

      _stopwatch
        ..reset()
        ..start();

      state = LessonState(
        leccion: leccion,
        ejercicioActual: primero,
        totalEjercicios: ejercicios.length,
        vidas: AppConfig.vidasPorLeccion,
        dominioActual: progreso.nivelDominio,
        dificultadObjetivo: targetDifficulty,
        erroresConsecutivos: progreso.rachaErroresConsecutivos,
        refuerzoActivo: needsReinforcement,
        dominioAntes: progreso.nivelDominio,
        dificultadAntes: progreso.dificultadActual,
      );
    } on Object catch (error) {
      if (!mounted) return;
      state = LessonState.error('No pudimos cargar la lección: $error');
    }
  }

  void seleccionarOpcion(int opcionId) {
    final ejercicio = state.ejercicioActual;
    if (ejercicio == null || state.respuestaVerificada || state.isLoading) {
      return;
    }
    final existe = ejercicio.opciones.any((opcion) => opcion.id == opcionId);
    if (!existe) return;
    state = state.copyWith(opcionSeleccionada: opcionId);
  }

  Future<void> comprobarRespuesta() async {
    final ejercicio = state.ejercicioActual;
    final opcionId = state.opcionSeleccionada;
    if (ejercicio == null ||
        opcionId == null ||
        state.respuestaVerificada ||
        state.isLoading) {
      return;
    }

    final opcion = ejercicio.opciones.firstWhere(
      (item) => item.id == opcionId,
      orElse: () => ejercicio.opciones.first,
    );
    final esCorrecta = opcion.esCorrecta;

    _stopwatch.stop();
    final tiempoMs = math.max(1, _stopwatch.elapsedMilliseconds);

    final decision = AdaptiveCalculator.evaluateAnswer(
      currentMastery: state.dominioActual,
      isCorrect: esCorrecta,
      difficulty: ejercicio.nivelDificultad,
      responseTimeMs: tiempoMs,
      expectedTimeMs: ejercicio.tiempoEstimadoMs,
      previousConsecutiveErrors: state.erroresConsecutivos,
    );

    final xp = GamificationRules.xpForAttempt(
      isCorrect: esCorrecta,
      difficulty: ejercicio.nivelDificultad,
      responseTimeMs: tiempoMs,
      expectedTimeMs: ejercicio.tiempoEstimadoMs,
    );

    try {
      final resultado = await _repository.registrarIntento(
        usuarioId: _request.usuarioId,
        moduloId: _request.moduloId,
        ejercicio: ejercicio,
        esCorrecto: esCorrecta,
        tiempoRespuestaMs: tiempoMs,
        nuevoDominio: decision.newMastery,
        nuevaDificultad: decision.targetDifficulty,
        rachaErroresConsecutivos: decision.newConsecutiveErrors,
        xpGanado: xp,
      );

      if (!mounted) return;

      _onDataChanged?.call();

      final vidasRestantes =
          esCorrecta ? state.vidas : math.max(0, state.vidas - 1);

      state = state.copyWith(
        respuestaVerificada: true,
        esCorrecta: esCorrecta,
        vidas: vidasRestantes,
        xpSesion: state.xpSesion + resultado.xpGanado,
        dominioActual: decision.newMastery,
        dificultadObjetivo: decision.targetDifficulty,
        erroresConsecutivos: decision.newConsecutiveErrors,
        refuerzoActivo: decision.needsReinforcement,
        intentos: <IntentoEjercicio>[
          ...state.intentos,
          resultado.intento,
        ],
        respondidos: state.respondidos + 1,
        correctos: state.correctos + (esCorrecta ? 1 : 0),
        ultimaDecision: decision,
      );
    } on Object catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        error: 'No se pudo registrar el intento: $error',
      );
    }
  }

  Future<void> continuar() async {
    if (!state.respuestaVerificada) return;

    if (state.vidas <= 0 || _pendientes.isEmpty) {
      await _finalizar();
      return;
    }

    final siguiente = _engine.selectNextExercise(
      remaining: _pendientes,
      targetDifficulty: state.dificultadObjetivo,
      reinforcement: state.refuerzoActivo,
    );
    _pendientes.remove(siguiente);

    _stopwatch
      ..reset()
      ..start();

    state = state.copyWith(
      ejercicioActual: siguiente,
      opcionSeleccionada: null,
      respuestaVerificada: false,
      esCorrecta: null,
      ultimaDecision: null,
    );
  }

  Future<void> _finalizar() async {
    if (state.resumen != null || state.isLoading) return;

    try {
      final resumen = await _repository.finalizarLeccion(
        usuarioId: _request.usuarioId,
        moduloId: _request.moduloId,
        leccion: _leccion,
        intentosSesion: state.intentos,
        dominioAntes: state.dominioAntes,
        dificultadAntes: state.dificultadAntes,
        respuestasTotales: state.respondidos,
        respuestasCorrectas: state.correctos,
        vidasRestantes: state.vidas,
      );

      if (!mounted) return;
      _onDataChanged?.call();
      state = state.copyWith(resumen: resumen);
    } on Object catch (error) {
      if (!mounted) return;
      state = state.copyWith(error: 'No se pudo cerrar la lección: $error');
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }
}
