import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/category.dart';
import '../../widgets/empty_state.dart';
import 'category_editor.dart';

final categoriesStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: async.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.folder_open,
                title: 'No categories',
                body: 'Group your reminders by adding a category.',
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return ListTile(
                    leading: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${c.colorHex.replaceFirst('#', '')}', radix: 16)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: Text(c.iconName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(categoryRepositoryProvider).delete(c.id),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CategoryEditorScreen(existing: c),
                    )),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const CategoryEditorScreen(),
        )),
        child: const Icon(Icons.add),
      ),
    );
  }
}
