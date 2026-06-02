import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:flutter/material.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageURLController = TextEditingController();
  final TextEditingController _typeController =
      TextEditingController(text: 'standard');
  final TextEditingController _orderController =
      TextEditingController(text: '0');
  bool isActive = true;
  @override
  void dispose() {
    _nameController.dispose();
    _imageURLController.dispose();
    _typeController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submitData() {
    final Map<String, dynamic> newCategoryPayload = {
      "name": _nameController.text,
      "image_url":
          _imageURLController.text.isEmpty ? null : _imageURLController.text,
      "type": _typeController.text,
      "order": int.tryParse(_orderController.text) ?? 0,
      "is_active": isActive
    };
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة الفئة بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: 
    Scaffold(appBar: AppBar(
      title: const Text('اضافة قسم جديد'),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.deepForest,
      elevation: 1,
    ),
    body:Center(
      child:Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24.0),
        child: Form(
              key: _formKey,
              child:ListView(
                children:[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم القسم*'
                      ,border:OutlineInputBorder(),

                    ),
                  )

                ],
              )
              )
      )
    )
    ));
  }
}
