import 'package:driving_quiz_app/models/CategoryModel.dart';
import 'package:driving_quiz_app/views/CreateCategoryScreen.dart';
import 'package:driving_quiz_app/views/ManageLevelScreen.dart';
import 'package:flutter/material.dart';

class CategoryLevelsDashboardScreen extends StatefulWidget {
  final CategoryModel category;
  final List<dynamic> supportedLanguages;

  const CategoryLevelsDashboardScreen({
    Key? key,
    required this.category,
    required this.supportedLanguages,
  }) : super(key: key);

  @override
  State<CategoryLevelsDashboardScreen> createState() =>
      _CategoryLevelsDashboardScreenState();
}

class _CategoryLevelsDashboardScreenState
    extends State<CategoryLevelsDashboardScreen> {
  List<dynamic> _levels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLevelsForCategory();
  }

  Future<void> _fetchLevelsForCategory() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _levels = List.generate(
          12,
          (index) => {
                'id': 'lvl_$index',
                'level_number': index + 1,
                'questions_count': 30,
                'order': index + 1,
                'is_active': true,
                'translations': [
                  {'locale': 'ar', 'name': 'المستوى ${index + 1}'},
                  {'locale': 'en', 'name': 'Level ${index + 1}'}
                ]
              });
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String categoryName = widget.category.nameAr ?? 'تؤوريا';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('إدارة مستويات: $categoryName'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _levels.length >= 30
                ? null
                : () async {
                    final bool? refresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageLevelScreen(
                          category: widget.category,
                        ),
                      ),
                    );
                    if (refresh == true) _fetchLevelsForCategory();
                  },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة مستوى جديد',
                style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor:
                  _levels.length >= 30 ? Colors.grey : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المستويات المتاحة (${_levels.length} / 30)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            _levels.length >= 30 ? Colors.red : Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // READ OPERATION
                  Expanded(
                    child: ListView.builder(
                      itemCount: _levels.length,
                      itemBuilder: (context, index) {
                        final level = _levels[index];
                        final String levelName =
                            level['translations'][0]['name'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text('${level['level_number']}',
                                  style: const TextStyle(color: Colors.green)),
                            ),
                            title: Text(levelName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'عدد الأسئلة: ${level['questions_count']} | الترتيب: ${level['order']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // UPDATE OPERATION (Modified to trigger navigation)
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () => _openLevelForm(level),
                                ),
                                // DELETE OPERATION
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDeleteLevel(level['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Handles updating existing levels by navigating to the form with payload data
  void _openLevelForm(Map<String, dynamic>? level) async {
    final bool? refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLevelScreen(
          category: widget.category,
          level: level,
        ),
      ),
    );
    if (refresh == true) _fetchLevelsForCategory();
  }

  void _confirmDeleteLevel(String levelId) {
    print("Triggering delete request for: $levelId");
  }
}
