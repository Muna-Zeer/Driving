import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ManageLevelScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final Map<String, dynamic>? level;
  final List<dynamic> supportedLanguages;

  const ManageLevelScreen(
      {Key? key,
      required this.category,
      this.level,
      required this.supportedLanguages})
      : super(key: key);
  @override
  _ManageLevelScreenState createState() => _ManageLevelScreenState();
}

class ManageLevelScreenState extends State<ManageLevelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _nameControllers = {};
  final _sortOrderController = TextEditingController();
  bool _isActive = true;
  bool get _isEditMode => widget.level != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length:width.supportedLanguages.length.vsync.this);
     for( var lang in widget.supportedLanguages){
      final Map<String,dynamic> langMap = lang as Map<String,dynamic>;
      final String langCode = langMap['code']?.toString() ?? 'en';
      String initialName = '';

      if(_isEditMode){
        final List <dynamic> translations = widget.level!['translations'] ?? [];
        final existingTranslation = translations.firstWhere((test)=>test['locale']==langCode,orElse:()=>null);
        initialName = existingTranslation != null  ? existingTranslation['name'] ??'': '';
      }
         _nameControllers[langCode] = TextEditingController(text:initialName);

     }
     if(_isEditMode){
      _sortOrderController.text = widget.level!['order']?.toString() ?? '1';
      _isActive = widget.level!['is_active'] ?? true;

     }
  }
}
