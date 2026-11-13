import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/category.dart';

class CategoryEditorScreen extends ConsumerStatefulWidget {
  final CategoryEntity? existing;
  const CategoryEditorScreen({super.key, this.existing});
  @override
  ConsumerState<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends ConsumerState<CategoryEditorScreen> {
  final _nameCtrl = TextEditingController();
  String _colorHex = '#6366F1';
  String _icon = 'folder';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _colorHex = widget.existing!.colorHex;
      _icon = widget.existing!.iconName;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final repo = ref.read(categoryRepositoryProvider);
    if (widget.existing != null) {
      await repo.upsert(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        colorHex: _colorHex,
        iconName: _icon,
      ));
    } else {
      await repo.create(
        id: newId(),
        name: _nameCtrl.text.trim(),
        colorHex: _colorHex,
        iconName: _icon,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New Category' : 'Edit Category'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Category Name'),
          ),
          const SizedBox(height: 24),
          const Text('Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: AppColors.categoryPalette.map((c) {
              final hex = '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 20,
                  child: _colorHex == hex ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
