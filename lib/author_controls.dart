import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';

class AuthorControls extends StatefulWidget {
  final FirebaseFirestore db; // Pass db instance for better testability

  AuthorControls({super.key, required this.db});

  @override
  State<AuthorControls> createState() => _AuthorControlsState();
}

class _AuthorControlsState extends State<AuthorControls> {
  // This list will hold the ContentBlocks we are composing
  final List<BlogEntry_ContentBlock> _contentBlocks = [];

  // Controllers for the input fields for a new ContentBlock
  final _titleController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();

  void _addContentBlock() {
    if (_titleController.text.isEmpty &&
        _linkUrlController.text.isEmpty &&
        _imageUrlController.text.isEmpty) {
      // Don't add empty blocks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Please fill at least one field for the content block.')),
      );
      return;
    }

    final newBlock = BlogEntry_ContentBlock();
    if (_titleController.text.isNotEmpty) {
      newBlock.title = _titleController.text;
    }
    if (_linkUrlController.text.isNotEmpty) {
      newBlock.linkUrl = _linkUrlController.text;
    }
    if (_imageUrlController.text.isNotEmpty) {
      newBlock.imageUrl = _imageUrlController.text;
    }

    setState(() {
      _contentBlocks.add(newBlock);
      // Clear fields after adding
      _titleController.clear();
      _linkUrlController.clear();
      _imageUrlController.clear();
    });
    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  void _removeContentBlock(int index) {
    setState(() {
      _contentBlocks.removeAt(index);
    });
  }

  Future<void> _submitBlogEntry() async {
    if (_contentBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Cannot submit an empty blog entry. Add some content blocks first.')),
      );
      return;
    }

    final blogEntry = BlogEntry();
    blogEntry.content.addAll(_contentBlocks);

    try {
      String collectionName = AppSection.education.firestoreCollection;

      final String blogEntryJsonString = blogEntry.writeToJson();

      // Protobuf messages have a .writeToBuffer() method to serialize
      // Firestore can store bytes (Uint8List) using Blob type
      final Map<String, dynamic> dataToSave = {
        'entry': blogEntryJsonString,
      };


      DocumentReference docRef = await widget.db.collection(collectionName).add(
          dataToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BlogEntry submitted with ID: ${docRef.id}')),
      );
      setState(() {
        _contentBlocks.clear(); // Clear for next entry
      });
    } catch (e) {
      print('Error submitting BlogEntry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting entry: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Using Scaffold for easier layout and SnackBar
      appBar: AppBar(
        title: const Text('Author Controls - New Blog Entry'),
        automaticallyImplyLeading: false, // Assuming this is part of a larger conditional UI
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input fields for a new ContentBlock
            Text('New Content Block:', style: Theme
                .of(context)
                .textTheme
                .titleLarge),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
            ),
            TextField(
              controller: _linkUrlController,
              decoration: const InputDecoration(
                  labelText: 'Link URL (optional)'),
            ),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                  labelText: 'Image URL (optional)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_box),
              label: const Text('Add Content Block'),
              onPressed: _addContentBlock,
            ),
            const SizedBox(height: 20),
            Text('Current Content Blocks (${_contentBlocks.length}):',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleLarge),
            const Divider(),
            // List of added ContentBlocks
            Expanded(
              child: _contentBlocks.isEmpty
                  ? const Center(child: Text('No content blocks added yet.'))
                  : ListView.builder(
                itemCount: _contentBlocks.length,
                itemBuilder: (context, index) {
                  final block = _contentBlocks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(block.hasTitle() ? block.title : 'No Title'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (block.hasLinkUrl()) Text(
                              'Link: ${block.linkUrl}'),
                          if (block.hasImageUrl()) Text(
                              'Image: ${block.imageUrl}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => _removeContentBlock(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            // Submit button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Submit Blog Entry'),
                onPressed: _submitBlogEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}