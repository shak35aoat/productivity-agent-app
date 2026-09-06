import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/task_provider.dart';
import '../providers/xp_provider.dart';
import '../models/task_model.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  static const _blue = Color(0xFF2563EB);
  static const _bg = Color(0xFFF0F9FF);
  static const _fg = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        title: const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddTaskDialog(context),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: _blue));
          }

          return Column(
            children: [
              _buildSummaryBanner(context, provider),
              if (provider.todayTasks.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: _blue.withValues(alpha: 0.08), shape: BoxShape.circle),
                          child: const Icon(Icons.task_alt_rounded, size: 60, color: _blue),
                        ),
                        const SizedBox(height: 16),
                        const Text('All clear for today!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _fg)),
                        const SizedBox(height: 8),
                        const Text('Swipe right to complete, left to delete', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: provider.todayTasks.length,
                    itemBuilder: (context, index) =>
                        _TaskCard(task: provider.todayTasks[index]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: _blue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryBanner(BuildContext context, TaskProvider provider) {
    final done = provider.completedToday;
    final total = provider.todayTasks.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Progress", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('$done of $total tasks done', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'medium';
    String category = 'other';
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Add Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  filled: true,
                  fillColor: const Color(0xFFF0F9FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  filled: true,
                  fillColor: const Color(0xFFF0F9FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        filled: true,
                        fillColor: const Color(0xFFF0F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (v) => setState(() => priority = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: const Color(0xFFF0F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'study', child: Text('Study')),
                        DropdownMenuItem(value: 'bcs_prep', child: Text('BCS Prep')),
                        DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                        DropdownMenuItem(value: 'personal', child: Text('Personal')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: _blue),
                      const SizedBox(width: 10),
                      Text(
                        dueDate == null ? 'Set due date (optional)' : 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate!)}',
                        style: TextStyle(color: dueDate == null ? Colors.grey : _fg, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    context.read<TaskProvider>().createAndAdd(
                      title: titleController.text.trim(),
                      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      dueDate: dueDate,
                      priority: priority,
                      category: category,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(task.id),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) async {
                context.read<TaskProvider>().completeTask(task.id);
                await context.read<XpProvider>().addXp(XpRewards.taskComplete);
              },
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              icon: Icons.check_rounded,
              label: 'Done',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => context.read<TaskProvider>().deleteTask(task.id),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: task.completed ? Colors.green.withValues(alpha: 0.2) : Colors.transparent),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (!task.completed) {
                    context.read<TaskProvider>().completeTask(task.id);
                    await context.read<XpProvider>().addXp(XpRewards.taskComplete);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.completed ? const Color(0xFF059669) : Colors.transparent,
                    border: Border.all(
                      color: task.completed ? const Color(0xFF059669) : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: task.completed ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: task.completed ? Colors.grey : const Color(0xFF0F172A),
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.description != null) ...[
                      const SizedBox(height: 2),
                      Text(task.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _PriorityBadge(priority: task.priority),
                        const SizedBox(width: 6),
                        _CategoryBadge(category: task.category),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.schedule_rounded, size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(DateFormat('MMM dd').format(task.dueDate!), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color c;
    switch (priority) {
      case 'high': c = const Color(0xFFDC2626); break;
      case 'medium': c = const Color(0xFFF59E0B); break;
      default: c = const Color(0xFF059669);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(priority.toUpperCase(), style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w700)),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(category.replaceAll('_', ' '), style: const TextStyle(fontSize: 9, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
    );
  }
}
