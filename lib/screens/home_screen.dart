// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _taskCtrl = TextEditingController();

  // OPTIMIZATION: Create the stream variable here
  late Stream<List<Map<String, dynamic>>> _tasksStream;

  @override
  void initState() {
    super.initState();
    // OPTIMIZATION: Initialize it once to keep the connection alive
    _tasksStream = _db.getTasksStream();
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "New Task",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _taskCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "What needs to be done?",
                border: OutlineInputBorder(),
              ),
              // Allow submitting by pressing "Enter" on keyboard
              onSubmitted: (_) => _submitTask(),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: _submitTask,
              child: const Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTask() {
    if (_taskCtrl.text.isNotEmpty) {
      _db.addTask(_taskCtrl.text.trim());
      _taskCtrl.clear();
      Navigator.pop(context); // Close the modal immediately
      // No need to refresh; the Stream will update the UI automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          "TaskFlow",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _db.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _tasksStream, // Use the stable stream variable
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No tasks yet!",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final tasks = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isDone = task['is_completed'] as bool;
              final taskId = task['id'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Slidable(
                  key: ValueKey(taskId), // Important for performance
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _db.deleteTask(taskId),
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        activeColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        value: isDone,
                        onChanged: (val) {
                          // The UI will update instantly via Stream when Supabase confirms the change
                          _db.toggleTask(taskId, isDone);
                        },
                      ),
                      title: Text(
                        task['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone ? Colors.grey : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
