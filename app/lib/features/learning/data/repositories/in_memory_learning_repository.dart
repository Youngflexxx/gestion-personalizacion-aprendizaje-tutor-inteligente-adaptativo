import 'dart:math' as math;

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/usuario.dart';
import '../../domain/entities/ejercicio.dart';
import '../../domain/entities/gamificacion_usuario.dart';
import '../../domain/entities/insignia.dart';
import '../../domain/entities/intento_ejercicio.dart';
import '../../domain/entities/leccion.dart';
import '../../domain/entities/modulo.dart';
import '../../domain/entities/progreso_modulo.dart';
import '../../domain/models/leccion_estado.dart';
import '../../domain/models/module_overview.dart';
import '../../domain/models/registro_intento_resultado.dart';
import '../../domain/models/resumen_leccion.dart';
import '../../domain/repositories/learning_repository.dart';
import '../../domain/services/gamification_rules.dart';
import '../datasources/seed_data_source.dart';

/// Implementación local del repositorio, precargada con `SeedDatabase`
/// (espejo de `database/03_seed.sql`).
///
/// Mantiene el estado en memoria durante la sesión de la app. Al conectar la
/// API/PostgreSQL basta con crear otra implementación de `LearningRepository`
/// y cambiarla en `learningRepositoryProvider`.
class InMemoryLearningRepository implements LearningRepository {
  InMemoryLearningRepository({
    SeedDatabase? seed,
    DateTime Function()? clock,
  })  : _seed = seed ?? SeedDatabase.create(),
        _clock = clock ?? DateTime.now {
    _gamificacion = {
      for (final item in _seed.gamificacion) item.usuarioId: item,
    };
    _progreso = {
      for (final item in _seed.progreso)
        _progressKey(item.usuarioId, item.moduloId): item,
    };
    _intentos = List<IntentoEjercicio>.of(_seed.intentos);
    _nextIntentoId = _intentos.isEmpty
        ? 1
        : _intentos.map((intento) => intento.id).reduce(math.max) + 1;
    _insigniasObtenidas = {
      for (final item in _seed.usuarioInsignias)
        _badgeKey(item.usuarioId, item.insigniaId),
    };
    _bonusOtorgados = <String>{};
    // El seed ya incluye el bonus de las lecciones completadas por Carlos.
    for (final estudiante in _estudiantesSync) {
      for (final leccion in _seed.lecciones) {
        if (_leccionCompletadaSync(estudiante.id, leccion)) {
          _bonusOtorgados.add(_lessonKey(estudiante.id, leccion.id));
        }
      }
    }
  }

  final SeedDatabase _seed;
  final DateTime Function() _clock;

  late final Map<int, GamificacionUsuario> _gamificacion;
  late final Map<String, ProgresoModulo> _progreso;
  late final List<IntentoEjercicio> _intentos;
  late final Set<String> _insigniasObtenidas;
  late final Set<String> _bonusOtorgados;
  late int _nextIntentoId;

  static String _progressKey(int usuarioId, int moduloId) =>
      '$usuarioId:$moduloId';

  static String _badgeKey(int usuarioId, int insigniaId) =>
      '$usuarioId:$insigniaId';

  static String _lessonKey(int usuarioId, int leccionId) =>
      '$usuarioId:$leccionId';

  List<Usuario> get _estudiantesSync {
    final estudiantes = _seed.usuarios
        .where((usuario) => usuario.rolId == 1 && usuario.activo)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return estudiantes;
  }

  Usuario _usuarioSync(int usuarioId) {
    for (final usuario in _seed.usuarios) {
      if (usuario.id == usuarioId) return usuario;
    }
    throw NotFoundFailure('No existe el usuario $usuarioId.');
  }

  Modulo _moduloSync(int moduloId) {
    for (final modulo in _seed.modulos) {
      if (modulo.id == moduloId) return modulo;
    }
    throw NotFoundFailure('No existe el módulo $moduloId.');
  }

  Leccion _leccionSync(int leccionId) {
    for (final leccion in _seed.lecciones) {
      if (leccion.id == leccionId) return leccion;
    }
    throw NotFoundFailure('No existe la lección $leccionId.');
  }

  Leccion? _leccionSyncOrNull(int leccionId) {
    for (final leccion in _seed.lecciones) {
      if (leccion.id == leccionId) return leccion;
    }
    return null;
  }

  List<Leccion> _leccionesSync(int moduloId) {
    final lecciones = _seed.lecciones
        .where((leccion) => leccion.moduloId == moduloId)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
    return lecciones;
  }

  List<Ejercicio> _ejerciciosSync(int leccionId) {
    final ejercicios = _seed.ejercicios
        .where((ejercicio) => ejercicio.leccionId == leccionId && ejercicio.activo)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return ejercicios;
  }

  Ejercicio? _ejercicioSyncOrNull(int ejercicioId) {
    for (final ejercicio in _seed.ejercicios) {
      if (ejercicio.id == ejercicioId) return ejercicio;
    }
    return null;
  }

  GamificacionUsuario _gamificacionSync(int usuarioId) {
    final existente = _gamificacion[usuarioId];
    if (existente != null) return existente;
    final nueva = GamificacionUsuario(
      usuarioId: usuarioId,
      xpTotal: 0,
      nivelActual: 1,
      rachaDiasActual: 0,
      mejorRachaDias: 0,
      ultimaFechaPractica: null,
    );
    _gamificacion[usuarioId] = nueva;
    return nueva;
  }

  ProgresoModulo _progresoSync(int usuarioId, int moduloId) {
    final existente = _progreso[_progressKey(usuarioId, moduloId)];
    if (existente != null) return existente;
    final nuevo = ProgresoModulo(
      usuarioId: usuarioId,
      moduloId: moduloId,
      nivelDominio: 20,
      dificultadActual: 1,
      rachaErroresConsecutivos: 0,
      estado: EstadoProgreso.enProgreso,
      actualizadoEn: _clock(),
    );
    _progreso[_progressKey(usuarioId, moduloId)] = nuevo;
    return nuevo;
  }

  bool _tieneAcierto(int usuarioId, int ejercicioId) {
    return _intentos.any(
      (intento) =>
          intento.usuarioId == usuarioId &&
          intento.ejercicioId == ejercicioId &&
          intento.esCorrecto,
    );
  }

  bool _leccionCompletadaSync(int usuarioId, Leccion leccion) {
    final ejercicios = _ejerciciosSync(leccion.id);
    if (ejercicios.isEmpty) return false;
    return ejercicios.every(
      (ejercicio) => _tieneAcierto(usuarioId, ejercicio.id),
    );
  }

  Set<int> _leccionesCompletadasSync(int usuarioId, int moduloId) {
    final completadas = <int>{};
    for (final leccion in _leccionesSync(moduloId)) {
      if (_leccionCompletadaSync(usuarioId, leccion)) {
        completadas.add(leccion.id);
      }
    }
    return completadas;
  }

  @override
  Future<List<Usuario>> obtenerEstudiantes() async => _estudiantesSync;

  @override
  Future<Usuario> obtenerUsuario(int usuarioId) async =>
      _usuarioSync(usuarioId);

  @override
  Future<GamificacionUsuario> obtenerGamificacion(int usuarioId) async =>
      _gamificacionSync(usuarioId);

  @override
  Future<ProgresoModulo> obtenerProgreso(int usuarioId, int moduloId) async =>
      _progresoSync(usuarioId, moduloId);

  @override
  Future<Modulo> obtenerModulo(int moduloId) async => _moduloSync(moduloId);

  @override
  Future<List<Leccion>> obtenerLecciones(int moduloId) async =>
      _leccionesSync(moduloId);

  @override
  Future<Leccion> obtenerLeccion(int leccionId) async =>
      _leccionSync(leccionId);

  @override
  Future<List<Ejercicio>> obtenerEjercicios(int leccionId) async =>
      _ejerciciosSync(leccionId);

  @override
  Future<Set<int>> obtenerLeccionesCompletadas(
    int usuarioId,
    int moduloId,
  ) async =>
      _leccionesCompletadasSync(usuarioId, moduloId);

  @override
  Future<List<IntentoEjercicio>> obtenerIntentos(
    int usuarioId, {
    int? moduloId,
  }) async {
    final intentos = _intentos.where((intento) {
      if (intento.usuarioId != usuarioId) return false;
      if (moduloId == null) return true;
      final ejercicio = _ejercicioSyncOrNull(intento.ejercicioId);
      if (ejercicio == null) return false;
      final leccion = _leccionSyncOrNull(ejercicio.leccionId);
      return leccion?.moduloId == moduloId;
    }).toList()
      ..sort((a, b) => b.fechaIntento.compareTo(a.fechaIntento));
    return intentos;
  }

  @override
  Future<ModuleOverview> obtenerResumenModulo(
    int usuarioId,
    int moduloId,
  ) async {
    final modulo = _moduloSync(moduloId);
    final lecciones = _leccionesSync(moduloId);
    final estados = <LeccionEstado>[];
    var anteriorCompletada = true;

    for (final leccion in lecciones) {
      final ejercicios = _ejerciciosSync(leccion.id);
      final correctos = ejercicios
          .where((ejercicio) => _tieneAcierto(usuarioId, ejercicio.id))
          .length;
      final completada =
          ejercicios.isNotEmpty && correctos == ejercicios.length;
      final estado = completada
          ? EstadoLeccion.completada
          : anteriorCompletada
              ? EstadoLeccion.disponible
              : EstadoLeccion.bloqueada;
      estados.add(
        LeccionEstado(
          leccion: leccion,
          estado: estado,
          ejerciciosTotales: ejercicios.length,
          ejerciciosCorrectos: correctos,
        ),
      );
      anteriorCompletada = completada;
    }

    return ModuleOverview(
      modulo: modulo,
      lecciones: estados,
      progreso: _progresoSync(usuarioId, moduloId),
      gamificacion: _gamificacionSync(usuarioId),
    );
  }

  @override
  Future<RegistroIntentoResultado> registrarIntento({
    required int usuarioId,
    required int moduloId,
    required Ejercicio ejercicio,
    required bool esCorrecto,
    required int tiempoRespuestaMs,
    required double nuevoDominio,
    required int nuevaDificultad,
    required int rachaErroresConsecutivos,
    required int xpGanado,
  }) async {
    _usuarioSync(usuarioId);
    final now = _clock();

    final intento = IntentoEjercicio(
      id: _nextIntentoId++,
      usuarioId: usuarioId,
      ejercicioId: ejercicio.id,
      esCorrecto: esCorrecto,
      tiempoRespuestaMs: tiempoRespuestaMs < 1 ? 1 : tiempoRespuestaMs,
      dificultadAlMomento: ejercicio.nivelDificultad,
      xpGanado: xpGanado < 0 ? 0 : xpGanado,
      fechaIntento: now,
    );
    _intentos.add(intento);

    final dominio = nuevoDominio.clamp(0, 100).toDouble();
    final dificultad = nuevaDificultad.clamp(1, 5).toInt();
    final progresoActual = _progresoSync(usuarioId, moduloId);
    final progreso = progresoActual.copyWith(
      nivelDominio: dominio,
      dificultadActual: dificultad,
      rachaErroresConsecutivos:
          rachaErroresConsecutivos < 0 ? 0 : rachaErroresConsecutivos,
      estado: dominio >= 85
          ? EstadoProgreso.dominado
          : EstadoProgreso.enProgreso,
      actualizadoEn: now,
    );
    _progreso[_progressKey(usuarioId, moduloId)] = progreso;

    final gamificacionActual = _gamificacionSync(usuarioId);
    final nuevoXp = gamificacionActual.xpTotal + intento.xpGanado;
    final nuevaRacha = GamificationRules.nextStreak(
      currentStreak: gamificacionActual.rachaDiasActual,
      lastPractice: gamificacionActual.ultimaFechaPractica,
      today: now,
    );
    final gamificacion = gamificacionActual.copyWith(
      xpTotal: nuevoXp,
      nivelActual: GamificationRules.levelForXp(nuevoXp),
      rachaDiasActual: nuevaRacha,
      mejorRachaDias: math.max(gamificacionActual.mejorRachaDias, nuevaRacha),
      ultimaFechaPractica: DateTime(now.year, now.month, now.day),
    );
    _gamificacion[usuarioId] = gamificacion;

    return RegistroIntentoResultado(
      intento: intento,
      progreso: progreso,
      gamificacion: gamificacion,
    );
  }

  @override
  Future<ResumenLeccion> finalizarLeccion({
    required int usuarioId,
    required int moduloId,
    required Leccion leccion,
    required List<IntentoEjercicio> intentosSesion,
    required double dominioAntes,
    required int dificultadAntes,
    required int respuestasTotales,
    required int respuestasCorrectas,
    required int vidasRestantes,
  }) async {
    _usuarioSync(usuarioId);
    final now = _clock();
    final completada = _leccionCompletadaSync(usuarioId, leccion);
    final xpSesion = intentosSesion.fold<int>(
      0,
      (total, intento) => total + intento.xpGanado,
    );

    var xpBonus = 0;
    if (completada) {
      final claveBonus = _lessonKey(usuarioId, leccion.id);
      if (_bonusOtorgados.add(claveBonus)) {
        xpBonus = leccion.xpRecompensa;
        final gamificacion = _gamificacionSync(usuarioId);
        final nuevoXp = gamificacion.xpTotal + xpBonus;
        _gamificacion[usuarioId] = gamificacion.copyWith(
          xpTotal: nuevoXp,
          nivelActual: GamificationRules.levelForXp(nuevoXp),
        );
      }
    }

    final nuevasInsignias = <Insignia>[];
    if (completada) {
      final completadasModulo =
          _leccionesCompletadasSync(usuarioId, leccion.moduloId);
      if (completadasModulo.length == 1) {
        final insignia = _otorgarInsignia(usuarioId, 'PRIMER_PASO', now);
        if (insignia != null) nuevasInsignias.add(insignia);
      }
      final totalLecciones = _leccionesSync(leccion.moduloId).length;
      if (totalLecciones > 0 && completadasModulo.length >= totalLecciones) {
        final insignia = _otorgarInsignia(usuarioId, 'EXPLORADOR_BD', now);
        if (insignia != null) nuevasInsignias.add(insignia);
      }
    }

    final gamificacion = _gamificacionSync(usuarioId);
    if (gamificacion.rachaDiasActual >= 3) {
      final insignia = _otorgarInsignia(usuarioId, 'RACHA_3', now);
      if (insignia != null) nuevasInsignias.add(insignia);
    }

    final progreso = _progresoSync(usuarioId, moduloId);
    final resumenIntentos = intentosSesion.map((intento) {
      final ejercicio = _ejercicioSyncOrNull(intento.ejercicioId);
      return ResumenIntento(
        enunciado: ejercicio?.enunciado ?? 'Ejercicio ${intento.ejercicioId}',
        esCorrecto: intento.esCorrecto,
        tiempoRespuestaMs: intento.tiempoRespuestaMs,
        dificultadAlMomento: intento.dificultadAlMomento,
      );
    }).toList();

    return ResumenLeccion(
      usuarioId: usuarioId,
      moduloId: moduloId,
      leccion: leccion,
      leccionCompletada: completada,
      xpSesion: xpSesion,
      xpBonus: xpBonus,
      respuestasTotales: respuestasTotales,
      respuestasCorrectas: respuestasCorrectas,
      dominioAntes: dominioAntes,
      dominioDespues: progreso.nivelDominio,
      dificultadAntes: dificultadAntes,
      dificultadDespues: progreso.dificultadActual,
      vidasRestantes: vidasRestantes,
      intentos: resumenIntentos,
      nuevasInsignias: nuevasInsignias,
    );
  }

  Insignia? _otorgarInsignia(int usuarioId, String codigo, DateTime fecha) {
    Insignia? insignia;
    for (final item in _seed.insignias) {
      if (item.codigo == codigo) {
        insignia = item;
        break;
      }
    }
    if (insignia == null) return null;
    final clave = _badgeKey(usuarioId, insignia.id);
    if (!_insigniasObtenidas.add(clave)) return null;
    return insignia;
  }
}
