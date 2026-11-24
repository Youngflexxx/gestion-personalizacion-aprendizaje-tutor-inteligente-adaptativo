import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_branding.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_panel.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../domain/entities/usuario.dart';
import '../providers/session_providers.dart';
import '../widgets/student_profile_card.dart';

/// Pantalla de entrada sin autenticación: selección de perfil de prueba.
class ProfileSelectorScreen extends ConsumerWidget {
  const ProfileSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final students = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    AppColors.primaryLight.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                AppBranding.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.10),
              scheme.surface,
              scheme.surface,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveCenter(
            maxWidth: 860,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentsProvider);
                await ref.read(studentsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const _IntroHeader(),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Elige un perfil',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      _CounterChip(
                        label: '${students.asData?.value.length ?? 0} demo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Acceso directo sin registro. Los datos provienen de '
                    'database/03_seed.sql y se actualizan durante la sesión.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  students.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return ErrorPanel(
                          message: 'No hay estudiantes cargados en el seed.',
                          onRetry: () => ref.invalidate(studentsProvider),
                        );
                      }
                      return Column(
                        children: [
                          for (final usuario in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: StudentProfileCard(
                                usuario: usuario,
                                onEnter: () =>
                                    _enter(context, ref, usuario),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stackTrace) => ErrorPanel(
                      message: '$error',
                      onRetry: () => ref.invalidate(studentsProvider),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _HowItWorksCard(),
                  const SizedBox(height: 16),
                  Text(
                    'Docente: el panel analítico se conectará a las vistas '
                    'SQL del Módulo 4 en la siguiente iteración.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enter(BuildContext context, WidgetRef ref, Usuario usuario) {
    ref.read(selectedStudentIdProvider.notifier).state = usuario.id;
    context.go('/module/${AppConfig.primerModuloId}');
  }
}

class _IntroHeader extends StatelessWidget {
  const _IntroHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            AppBranding.institution,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppBranding.academicTitle,
          style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
        ),
        const SizedBox(height: 10),
        Text(
          'Micro-aprendizaje adaptativo para aulas multigrado o numerosas: '
          'un motor que ajusta la dificultad, refuerza los errores y mide '
          'el dominio en tiempo real.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag(icon: Icons.menu_book_rounded, label: 'SABD'),
            _Tag(icon: Icons.groups_rounded, label: AppBranding.demoAulaName),
            _Tag(icon: Icons.verified_rounded, label: 'Datos demo'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.school_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppBranding.subject,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      color: scheme.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¿Qué puedes probar?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _Bullet(
            text: 'Ruta de 3 micro-lecciones con estados bloqueada, '
                'disponible y completada.',
          ),
          const _Bullet(
            text: 'Motor adaptativo: cada acierto o error ajusta tu dominio '
                'y la dificultad del siguiente ejercicio.',
          ),
          const _Bullet(
            text: 'XP, racha, vidas y retroalimentación pedagógica inmediata.',
          ),
          const SizedBox(height: 10),
          Text(
            'María empieza desde cero. Carlos ya completó las lecciones 1 y 2, '
            'con nivel 3 y 213 XP.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
