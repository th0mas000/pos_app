import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../theme/app_theme.dart';

class CategoryTabs extends StatefulWidget {
  final int? selectedCategoryId;
  final Function(int?) onCategorySelected;

  const CategoryTabs({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final categories = await database.select(database.categories).get();
    
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(
            label: 'ทั้งหมด',
            isSelected: widget.selectedCategoryId == null,
            onTap: () => widget.onCategorySelected(null),
          ),
          ..._categories.map((category) => _buildCategoryChip(
            label: category.name,
            isSelected: widget.selectedCategoryId == category.id,
            onTap: () => widget.onCategorySelected(category.id),
            color: category.color != null ? _parseColor(category.color!) : null,
          )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacing8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: color?.withOpacity(0.1),
        selectedColor: color ?? Theme.of(context).colorScheme.primary,
        showCheckmark: false,
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
