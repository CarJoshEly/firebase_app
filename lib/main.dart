import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config.dart';
import 'firestone_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebase_config);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas con Firebase',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final FirestoneService _service = FirestoneService();

  final List<String> _categories = [
    'General',
    'Trabajo',
    'Personal',
    'Importante',
    'Estudio',
  ];

  String _selectedCategory = 'General';

  Future<void> _addNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _service.addNote(text, _selectedCategory);
    _controller.clear();
    setState(() => _selectedCategory = 'General');
  }

  Future<void> _editNote(String id, String oldText, String? oldCategory) async {
    final ctrl = TextEditingController(text: oldText);
    String editCategory = (oldCategory != null && _categories.contains(oldCategory))
        ? oldCategory
        : _categories.first;

    final newText = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categories.contains(editCategory)
                  ? editCategory
                  : _categories.first,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => editCategory = v ?? editCategory,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'text': ctrl.text.trim(),
              'category': editCategory,
            }),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newText == null || newText.isEmpty) return;
    final text = newText['text'] ?? '';
    final newCategory = newText['category'] ?? oldCategory ?? 'General';
    await _service.updateNote(id, text, newCategory);
  }

  Future<void> _deleteNote(String id) async {
    await _service.deleteNote(id);
  }

  String _formatTimestamp(dynamic ts) {
    try {
      if (ts == null) return '';
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      if (ts is DateTime) {
        final dt = ts;
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      return ts.toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notas con Firebase')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe una nota...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : _categories.first,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedCategory = v);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addNote,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getNotesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notes = snapshot.data!.docs;
                if (notes.isEmpty) {
                  return const Center(child: Text('Sin notas aún'));
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, i) {
                    final doc = notes[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final text = data['text'] ?? '';
                    String category = data['category'] ?? 'General';
                    if (!_categories.contains(category)) {
                      category = 'General';
                      _service.updateNote(doc.id, text, category);
                    }
                    final createdAt = data['createdAt'];
                    final created = _formatTimestamp(createdAt);

                    return ListTile(
                      title: Text(text),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Categoría: $category'),
                          if (created.isNotEmpty) Text('Fecha: $created'),
                        ],
                      ),
                      onTap: () => _editNote(doc.id, text, category),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteNote(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 