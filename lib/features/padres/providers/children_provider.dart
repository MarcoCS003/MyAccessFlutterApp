import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../services/api_service.dart';
import '../models/child.dart';
import '../models/timeline_event.dart';

final childrenProvider =
    StateNotifierProvider<ChildrenNotifier, AsyncValue<List<Child>>>((ref) {
      return ChildrenNotifier();
    });

final childTimelineProvider = FutureProvider.family<List<TimelineEvent>, int>((
  ref,
  childId,
) async {
  // El backend actual no expone un endpoint de asistencias por estudiante.
  // Se deja como lista vacía para evitar errores 404; cuando exista el
  // endpoint, reemplazar por la llamada real a
  // `/students/$childId/attendances`.
  return <TimelineEvent>[];
});

/// Combina los timelines de todos los hijos vinculados para mostrar la
/// actividad reciente en el home del padre.
final recentActivityProvider =
    FutureProvider<List<(TimelineEvent event, String childName)>>((ref) async {
      final childrenAsync = ref.watch(childrenProvider);
      final children = childrenAsync.valueOrNull ?? [];
      if (children.isEmpty) return [];

      final timelines = await Future.wait(
        children.map((child) async {
          final events = await ref.watch(
            childTimelineProvider(child.id).future,
          );
          return events.map((e) => (e, child.name)).toList();
        }),
      );

      final allEvents = timelines.expand((events) => events).toList();
      allEvents.sort((a, b) => b.$1.recordedAt.compareTo(a.$1.recordedAt));
      return allEvents.take(10).toList();
    });

class ChildrenNotifier extends StateNotifier<AsyncValue<List<Child>>> {
  ChildrenNotifier({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(const AsyncValue.loading());

  /// Inicia la carga de hijos. Se llama explícitamente desde
  /// [MainNavigationScreen] para evitar peticiones automáticas antes de que
  /// el usuario esté autenticado.
  void initialize() {
    loadChildren();
  }

  final ApiService _apiService;

  Future<void> loadChildren() async {
    state = const AsyncValue.loading();

    try {
      debugPrint('[CHILDREN] Loading children from /api/user...');
      final response = await _apiService.get('/user');
      debugPrint('[CHILDREN] /api/user response: $response');
      final data = response as Map<String, dynamic>;
      final students = data['students'] as List<dynamic>? ?? [];
      final children = students
          .map((e) => Child.fromJson(e as Map<String, dynamic>))
          .toList();

      await _saveToHive(children);
      state = AsyncValue.data(children);
    } catch (e) {
      final cached = await _loadFromHive();
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached);
      } else if (e is Failure) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          ServerFailure('Error al cargar hijos: ${e.toString()}'),
          StackTrace.current,
        );
      }
    }
  }

  Future<void> linkChild(String code) async {
    final previousState = state;

    try {
      await _apiService.post('/vincular-alumno', data: {'codigo_alumno': code});

      // El backend no devuelve el estudiante vinculado, así que refrescamos
      // la lista completa desde /api/user para obtener los datos actualizados.
      await loadChildren();
    } catch (e) {
      state = previousState;
      if (e is Failure) {
        rethrow;
      }
      throw ServerFailure('Error al vincular alumno: ${e.toString()}');
    }
  }

  Future<void> _saveToHive(List<Child> children) async {
    try {
      final box = Hive.box(AppConstants.childrenBox);
      await box.put('items', children.map((c) => c.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving children to Hive: $e');
    }
  }

  Future<List<Child>> _loadFromHive() async {
    try {
      final box = Hive.box(AppConstants.childrenBox);
      final items = box.get('items', defaultValue: <Map<dynamic, dynamic>>[]);
      return (items as List)
          .map((e) => Child.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error loading children from Hive: $e');
      return [];
    }
  }
}
