class Habit {
  final String id;
  final String name;
  int colorValue; // color del hábito, guardado como número
  final DateTime createdAt;
  final Set<DateTime> completedDates;

  Habit({
    required this.id,
    required this.name,
    this.colorValue = 0xFF009688,
    DateTime? createdAt,
    Set<DateTime>? completedDates,
  })  : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? {};

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool isCompletedOn(DateTime date) =>
      completedDates.contains(_dateOnly(date));

  void toggleOn(DateTime date) {
    final day = _dateOnly(date);
    if (!completedDates.remove(day)) {
      completedDates.add(day);
    }
  }

  // Días seguidos que terminan hoy (o ayer, si hoy aún no está marcado)
  int get currentStreak {
    var day = _dateOnly(DateTime.now());

    if (!completedDates.contains(day)) {
      day = DateTime(day.year, day.month, day.day - 1);
    }

    var streak = 0;
    while (completedDates.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  // La secuencia más larga de días seguidos de todo el historial
  int get bestStreak {
    if (completedDates.isEmpty) return 0;

    final days = completedDates.toList()..sort();
    var best = 1;
    var current = 1;

    for (var i = 1; i < days.length; i++) {
      final prev = days[i - 1];
      final nextDay = DateTime(prev.year, prev.month, prev.day + 1);
      if (days[i] == nextDay) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'completedDates':
            completedDates.map((d) => d.toIso8601String()).toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['color'] as int? ?? 0xFF009688,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedDates: (json['completedDates'] as List)
            .map((d) => DateTime.parse(d as String))
            .toSet(),
      );
}