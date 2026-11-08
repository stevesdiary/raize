import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../models/workout_models.dart';

class SetLoggingTable extends StatefulWidget {
  final List<WorkoutSetItem> sets;
  final Function(int setIndex, double weight, int reps) onLogSet;

  const SetLoggingTable({
    super.key,
    required this.sets,
    required this.onLogSet,
  });

  @override
  State<SetLoggingTable> createState() => _SetLoggingTableState();
}

class _SetLoggingTableState extends State<SetLoggingTable> {
  late List<TextEditingController> _weightControllers;
  late List<TextEditingController> _repsControllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant SetLoggingTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sets.length != widget.sets.length) {
      _initControllers();
    }
  }

  void _initControllers() {
    _weightControllers = widget.sets
        .map((s) => TextEditingController(text: s.weightKg > 0 ? s.weightKg.toString() : ''))
        .toList();
    _repsControllers = widget.sets
        .map((s) => TextEditingController(text: s.reps > 0 ? s.reps.toString() : ''))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _weightControllers) {
      c.dispose();
    }
    for (final c in _repsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('SET', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                flex: 2,
                child: Text('PREVIOUS', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                flex: 2,
                child: Text('KG', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text('REPS', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text('DONE', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 8),

          // Set Rows
          ...List.generate(widget.sets.length, (index) {
            final s = widget.sets[index];
            final isCompleted = s.isCompleted;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Set Number / Type
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted ? colors.primary.withAlpha(40) : colors.cardElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCompleted ? colors.primary : colors.borderSubtle,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.setType == 'warmup' ? 'W' : '${s.setOrder}',
                      style: TextStyle(
                        color: isCompleted ? colors.primary : colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Previous Record
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        s.previousBest,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Weight Input Field
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted ? colors.cardElevated : colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted ? colors.primary.withAlpha(60) : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _weightControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Reps Input Field
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted ? colors.cardElevated : colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted ? colors.primary.withAlpha(60) : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _repsControllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Checkmark Completion Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final weight = double.tryParse(_weightControllers[index].text) ?? s.weightKg;
                      final reps = int.tryParse(_repsControllers[index].text) ?? s.reps;
                      widget.onLogSet(index, weight, reps);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted ? colors.emerald : colors.cardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted ? colors.emerald : colors.border,
                          width: 1.5,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: colors.emerald.withAlpha(80),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: isCompleted ? Colors.white : colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

