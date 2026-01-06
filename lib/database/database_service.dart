import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getTasksStream() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at') // Sort by newest
        .map((data) => data);
  }

  Future<void> addTask(String title) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('tasks').insert({
      'user_id': userId,
      'title': title,
      'is_completed': false,
    });
  }

  Future<void> toggleTask(int id, bool currentValue) async {
    await _client
        .from('tasks')
        .update({'is_completed': !currentValue})
        .eq('id', id);
  }

  Future<void> deleteTask(int id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
