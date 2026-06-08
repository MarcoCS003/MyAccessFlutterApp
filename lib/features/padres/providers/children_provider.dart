import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelineEvent {
  final String id;
  final String title;
  final String time;
  final String date;
  final String description;
  final String type; // 'entry', 'exit', 'alert'

  const TimelineEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.date,
    required this.description,
    required this.type,
  });
}

class Child {
  final String id;
  final String name;
  final String grade;
  final String group;
  final String avatarUrl;
  final String status; // 'inside' or 'outside'
  final String lastEventText;
  final List<TimelineEvent> events;

  const Child({
    required this.id,
    required this.name,
    required this.grade,
    required this.group,
    required this.avatarUrl,
    required this.status,
    required this.lastEventText,
    required this.events,
  });

  Child copyWith({
    String? id,
    String? name,
    String? grade,
    String? group,
    String? avatarUrl,
    String? status,
    String? lastEventText,
    List<TimelineEvent>? events,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      group: group ?? this.group,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      lastEventText: lastEventText ?? this.lastEventText,
      events: events ?? this.events,
    );
  }
}

class ChildrenNotifier extends StateNotifier<List<Child>> {
  ChildrenNotifier()
      : super([
          const Child(
            id: '1',
            name: 'Mateo Pérez',
            grade: '4º Primaria',
            group: 'A',
            avatarUrl: 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?auto=format&fit=crop&w=150&q=80',
            status: 'inside',
            lastEventText: 'Entrada registrada a las 07:30 AM',
            events: [
              TimelineEvent(
                id: 'e1',
                title: 'Entrada Registrada',
                time: '07:30 AM',
                date: 'Hoy, 05 Jun',
                description: 'Acceso concedido por Torniquete Principal',
                type: 'entry',
              ),
              TimelineEvent(
                id: 'e2',
                title: 'Salida Registrada',
                time: '02:00 PM',
                date: 'Ayer, 04 Jun',
                description: 'Salida autorizada por Puerta A',
                type: 'exit',
              ),
              TimelineEvent(
                id: 'e3',
                title: 'Entrada Registrada',
                time: '07:25 AM',
                date: 'Ayer, 04 Jun',
                description: 'Acceso concedido por Torniquete Principal',
                type: 'entry',
              ),
            ],
          ),
          const Child(
            id: '2',
            name: 'Sofía Pérez',
            grade: '1º Secundaria',
            group: 'B',
            avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=150&q=80',
            status: 'outside',
            lastEventText: 'Salida registrada a las 02:05 PM (Ayer)',
            events: [
              TimelineEvent(
                id: 'e4',
                title: 'Salida Registrada',
                time: '02:05 PM',
                date: 'Ayer, 04 Jun',
                description: 'Salida autorizada por Puerta Principal',
                type: 'exit',
              ),
              TimelineEvent(
                id: 'e5',
                title: 'Entrada Registrada',
                time: '07:15 AM',
                date: 'Ayer, 04 Jun',
                description: 'Acceso concedido por Torniquete Secundario',
                type: 'entry',
              ),
              TimelineEvent(
                id: 'e6',
                title: 'Retardo Justificado',
                time: '07:45 AM',
                date: 'Mié, 03 Jun',
                description: 'Llegada tarde con justificante médico',
                type: 'alert',
              ),
            ],
          ),
        ]);

  void linkChildManually(String code) {
    final newId = (state.length + 1).toString();
    final newChild = Child(
      id: newId,
      name: 'Alumno ($code)',
      grade: 'Por definir',
      group: '-',
      avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=150&q=80',
      status: 'outside',
      lastEventText: 'Vinculado con código: $code',
      events: [
        const TimelineEvent(
          id: 'init',
          title: 'Vínculo Exitoso',
          time: 'Ahora',
          date: 'Hoy',
          description: 'Estudiante vinculado mediante código manual',
          type: 'alert',
        ),
      ],
    );
    state = [...state, newChild];
  }

  void addChild(String name, String grade, String group) {
    final newId = (state.length + 1).toString();
    final newChild = Child(
      id: newId,
      name: name,
      grade: grade,
      group: group,
      avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=150&q=80',
      status: 'outside',
      lastEventText: 'Vinculado exitosamente hoy',
      events: [
        const TimelineEvent(
          id: 'init',
          title: 'Vínculo Exitoso',
          time: 'Ahora',
          date: 'Hoy',
          description: 'Estudiante vinculado a la cuenta del tutor',
          type: 'alert',
        ),
      ],
    );
    state = [...state, newChild];
  }
}

final childrenProvider = StateNotifierProvider<ChildrenNotifier, List<Child>>((ref) {
  return ChildrenNotifier();
});
