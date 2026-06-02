import 'package:driving_quiz_app/widgets/AppColors.dart';
import 'package:driving_quiz_app/widgets/CustomTExtField.dart';
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
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('اضافة قسم جديد'),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.deepForest,
              elevation: 1,
            ),
            body: Center(
                child: Container(
                    constraints: const BoxConstraints(maxHeight: 600),
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            CustomTextField(
                              controller: _nameController,
                             
                                labelText: 'اسم القسم*',
                                validator: (value)=>
                                value==null||value.trim().isEmpty?'يرجى إدخال اسم القسم' : null,
                            ),
                            CustomTextField(
                    controller: _imageURLController,
                    labelText: 'رابط الصورة (Image URL)',
                    hintText: 'https://example.com/image.png',
                  ),
                  CustomTextField(
                    controller: _typeController,
                    labelText: 'نوع القسم (Type)',
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'يرجى تحديد النوع' : null,
                  ),
                  CustomTextField(
                    controller: _orderController,
                    labelText: 'الترتيب (Order)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'يرجى إدخال الترتيب الرقمي';
                      if (int.tryParse(value) == null) return 'الترتيب يجب أن يكون رقماً صحيحاً';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                          ],
                        ))))));
  }
}
