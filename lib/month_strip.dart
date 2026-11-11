import 'package:flutter/material.dart';

import 'models/habit.dart';

class MonthStrip extends StatefulWidget {
  final Habit habit;
  final ValueChanged<DateTime> onToggle;

  const MonthStrip({super.key, required this.habit, required this.onToggle});

  @override
  State<MonthStrip> createState() => _MonthStripState();
}

class _MonthStripState extends State<MonthStrip> {
  static const _months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  // Días cuyo número se muestra arriba (cámbialos a tu gusto)
  static const _labeledDays = {1, 5, 10, 15, 20, 25, 30};

  // Página inicial: mes actual + los dos siguientes
  static const int _firstPage = 1000;

  static const double _labelWidth = 34; // columna con el nombre del mes
  static const double _headerHeight = 14; // fila con los números
  static const double _rowHeight = 20; // alto de cada fila de mes

  final _controller = PageController(initialPage: _firstPage);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerHeight + _rowHeight * 3 + 4,
      child: PageView.builder(
        controller: _controller,
        itemCount: _firstPage * 2,
        itemBuilder: (context, page) {
          final monthOffset = (page - _firstPage) * 3;
          return _buildPage(monthOffset);
        },
      ),
    );
  }

  Widget _buildPage(int monthOffset) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final months = [
      for (var i = 0; i < 3; i++)
        DateTime(now.year, now.month + monthOffset + i),
    ];

    // Año(s) de los 3 meses visibles, ej. "2026" o "2026/27"
    final firstYear = months.first.year;
    final lastYear = months.last.year;
    final yearLabel = firstYear == lastYear
        ? '$firstYear'
        : '$firstYear/${(lastYear % 100).toString().padLeft(2, '0')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = ((constraints.maxWidth - _labelWidth) / 31).floorToDouble();

        return Column(
          children: [
            // Fila de números (solo los días de _labeledDays)
            SizedBox(
              height: _headerHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        yearLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  for (var d = 1; d <= 31; d++)
                    SizedBox(
                      width: cellW,
                      child: _labeledDays.contains(d)
                          ? OverflowBox(
                              // deja que el número se salga del ancho de la casilla
                              maxWidth: 24,
                              child: Text(
                                '$d',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            )
                          : null,
                    ),
                ],
              ),
            ),

            // Una fila por mes
            for (final m in months)
              SizedBox(
                height: _rowHeight,
                child: _monthRow(m, cellW, today, colors),
              ),
          ],
        );
      },
    );
  }

  Widget _monthRow(
    DateTime month,
    double cellW,
    DateTime today,
    ColorScheme colors,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final habitColor = Color(widget.habit.colorValue);

    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(
            _months[month.month - 1],
            style: const TextStyle(fontSize: 10),
          ),
        ),
        for (var d = 1; d <= 31; d++)
          if (d > daysInMonth)
            SizedBox(width: cellW) // el mes no tiene este día
          else
            _dayCell(
              DateTime(month.year, month.month, d),
              cellW,
              today,
              habitColor,
              colors,
            ),
      ],
    );
  }

  Widget _dayCell(
    DateTime date,
    double cellW,
    DateTime today,
    Color habitColor,
    ColorScheme colors,
  ) {
    final done = widget.habit.isCompletedOn(date);
    final isFuture = date.isAfter(today);
    final isToday = date == today;

    // Tamaño del círculo: un poco menor que el hueco, para dejar aire
    final size = (cellW - 2).clamp(4.0, 11.0).toDouble();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFuture ? null : () => widget.onToggle(date),
      child: Container(
        width: cellW,
        height: _rowHeight,
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle, // ← la forma de la casilla
            color: done
                ? habitColor
                : colors.onSurface.withOpacity(isFuture ? 0.05 : 0.14),
            border: isToday ? Border.all(color: habitColor, width: 1.5) : null,
          ),
        ),
      ),
    );
  }
}