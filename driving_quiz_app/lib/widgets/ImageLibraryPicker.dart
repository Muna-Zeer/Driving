
import 'package:flutter/material.dart';

class ImageLibraryPicker extends StatelessWidget {
  final Function(String selectedUrl) onImageSelected;

  const ImageLibraryPicker({Key? key, required this.onImageSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Image from Library'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('media_library').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs;

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final url = data['imageUrl'] ?? '';

                return InkWell(
                  onTap: () {
                    onImageSelected(url);
                    Navigator.pop(context);
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}