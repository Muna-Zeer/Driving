import 'package:driving_quiz_app/services/MediaService.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageLibraryDialog extends StatefulWidget {
  final Function(String selectedUrl) onImageSelected;

  const ImageLibraryDialog({Key? key, required this.onImageSelected})
      : super(key: key);

  @override
  State<ImageLibraryDialog> createState() => _ImageLibraryDialogState();
}

class _ImageLibraryDialogState extends State<ImageLibraryDialog> {
  late Future<List<dynamic>> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _refreshLibrary();
  }

  void _refreshLibrary() {
    setState(() {
      _mediaFuture = MediaService.fetchMediaLibrary();
    });
  }

  Future<void> _deleteMedia(String id) async {
    try {
      await MediaService.deleteMedia(id);
      _refreshLibrary();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete media: $e')));
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await MediaService.uploadImage(
        pickedFile: pickedFile,
        imageName: 'New Sign ${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) Navigator.pop(context);
      _refreshLibrary();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Media Library'),
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _pickAndUploadImage,
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: FutureBuilder<List<dynamic>>(
          future: _mediaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading images: ${snapshot.error}'));
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(child: Text('No images found in library.'));
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final url = item['image_url'] ?? '';

                return InkWell(
                  onTap: () {
                    widget.onImageSelected(url);
                    Navigator.pop(context);
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
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
