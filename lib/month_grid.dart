import 'package:flutter/material.dart';

import 'models/habit.dart';

class MonthGrid extends StatefulWidget {
  final Habit habit;
  final ValueChanged<DateTime> onToggle;

  const MonthGrid({super.key, required this.habit, required this.onToggle});

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  static const _months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  static const _weekdays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  static const double _cell = 20; // tamaño del cuadradito
  static const double _margin = 1;
  static const double _box = _cell + _margin * 2;

  late DateTime _month; // siempre el día 1 del mes que se muestra

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => IconButton(
        icon: Icon(icon),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday - 1;

    return SizedBox(
      width: _box * 7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mes con flechas
          Row(
            children: [
              _arrow(Icons.chevron_left, () => _changeMonth(-1)),
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              _arrow(Icons.chevron_right, () => _changeMonth(1)),
            ],
          ),

          // Letras de los días de la semana
          Row(
            children: [
              for (final d in _weekdays)
                SizedBox(
                  width: _box,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Siempre 6 filas, para que la tarjeta no cambie de alto
          for (var r = 0; r < 6; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  _cellAt(r * 7 + c - offset + 1, daysInMonth, today, colors),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cellAt(
    int day,
    int daysInMonth,
    DateTime today,
    ColorScheme colors,
  ) {
    // Hueco fuera del mes
    if (day < 1 || day > daysInMonth) {
      return const SizedBox(width: _box, height: _box);
    }

    final date = DateTime(_month.year, _month.month, day);
    final done = widget.habit.isCompletedOn(date);
    final isFuture = date.isAfter(today);
    final isToday = date == today;

    final habitColor = Color(widget.habit.colorValue);
    // Texto negro sobre colores claros, blanco sobre oscuros
    final textOnColor =
        habitColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: isFuture ? null : () => widget.onToggle(date),
      child: Container(
        width: _cell,
        height: _cell,
        margin: const EdgeInsets.all(_margin),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: done ? habitColor : colors.onSurface.withOpacity(0.08),
          border: isToday ? Border.all(color: habitColor, width: 1.5) : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 9,
            color: done
                ? textOnColor
                : colors.onSurface.withOpacity(isFuture ? 0.3 : 0.8),
          ),
        ),
      ),
    );
  }
}