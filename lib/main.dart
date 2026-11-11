import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'models/habit.dart';
import 'month_strip.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Barra de estado y de navegación del móvil en negro
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false, // quita la marca de debug
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Los primeros tres son tonos del azul principal
  static const _palette = [
    0xFF357A94, 0xFF7DB5CB, 0xFF245468, 0xFF00BCD4,
    0xFF4CAF50, 0xFF8BC34A, 0xFFFFC107, 0xFFFF9800,
    0xFFFF5722, 0xFFF44336, 0xFFE91E63, 0xFF9C27B0,
    0xFF673AB7, 0xFF3F51B5, 0xFF2196F3, 0xFF009688,
    0xFFCDDC39, 0xFFFFEB3B, 0xFF795548, 0xFF607D8B,
    0xFFAD1457, 0xFF00695C, 0xFFEF6C00, 0xFF9E9E9E,
  ];

  static const _weekdayNames = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo',
  ];
  static const _monthNames = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static const _cardMargin = EdgeInsets.symmetric(horizontal: 12, vertical: 4);

  final List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('habits');
    if (raw == null || !mounted) return;

    final loaded = (jsonDecode(raw) as List)
        .map((e) => Habit.fromJson(e as Map<String, dynamic>))
        .toList();
    setState(() => _habits.addAll(loaded));
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'habits',
      jsonEncode(_habits.map((h) => h.toJson()).toList()),
    );
  }

  // ---------- Colores ----------

  Widget _colorPicker({
    required int selected,
    required ValueChanged<int> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in _palette)
          GestureDetector(
            onTap: () => onSelect(c),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: selected == c
                    ? Border.all(color: AppColors.text, width: 3)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  // ---------- Diálogos ----------

  Future<void> _showCreateHabitDialog() async {
    final controller = TextEditingController();
    var selectedColor = _palette[_habits.length % _palette.length];

    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Nuevo hábito'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ej: Beber agua',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.black,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _colorPicker(
                  selected: selectedColor,
                  onSelect: (c) => setDialogState(() => selectedColor = c),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() => _habits.add(
            Habit(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              colorValue: selectedColor,
            ),
          ));
      _saveHabits();
    }
  }

  Future<void> _changeColor(Habit habit) async {
    final color = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Elegir color'),
        content: SingleChildScrollView(
          child: _colorPicker(
            selected: habit.colorValue,
            onSelect: (c) => Navigator.pop(context, c),
          ),
        ),
      ),
    );

    if (color != null) {
      setState(() => habit.colorValue = color);
      _saveHabits();
    }
  }

  // ---------- Piezas de la pantalla ----------

  // Cabecera: fecha de hoy y progreso del día
  Widget _buildSummary() {
    final now = DateTime.now();
    final done = _habits.where((h) => h.isCompletedOn(now)).length;
    final total = _habits.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_weekdayNames[now.weekday - 1]}, ${now.day} de ${_monthNames[now.month - 1]}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            '$done de $total completados hoy',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: AppColors.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded, size: 64, color: AppColors.accent),
          SizedBox(height: 16),
          Text(
            'Aún no tienes hábitos',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pulsa «Nuevo hábito» para crear el primero',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final habitColor = Color(habit.colorValue);
    final textOnHabit =
        habitColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final doneToday = habit.isCompletedOn(DateTime.now());

    return Padding(
      padding: _cardMargin,
      child: Dismissible(
        key: ValueKey(habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (_) {
          setState(() => _habits.remove(habit));
          _saveHabits();
        },
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: punto de color, nombre y checkbox de hoy
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => _changeColor(habit),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: habitColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'Hoy',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      Checkbox(
                        value: doneToday,
                        activeColor: habitColor,
                        checkColor: textOnHabit,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (_) {
                          setState(() => habit.toggleOn(DateTime.now()));
                          _saveHabits();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Meses
                MonthStrip(
                  habit: habit,
                  onToggle: (date) {
                    setState(() => habit.toggleOn(date));
                    _saveHabits();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis hábitos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.black,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: _habits.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _habits.length + 1, // +1 por la cabecera
              itemBuilder: (context, i) {
                if (i == 0) return _buildSummary();
                return _buildHabitCard(_habits[i - 1]);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHabitDialog,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo hábito'),
      ),
    );
  }
}