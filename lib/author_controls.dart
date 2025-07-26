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
  final _overallTitleController = TextEditingController();
  final _tagsController = TextEditingController(); // For comma-separated tags
  AppSection _selectedAppSection = AppSection.education; // Default to education
  bool _isLinktreeEntry = false; // Default to blog post

  void _addContentBlock() {
    if (_titleController.text.isEmpty &&
        _linkUrlController.text.isEmpty &&
        _imageUrlController.text.isEmpty) {
      // Don't add empty blocks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill at least one field for the content block.')),
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

    if (_isLinktreeEntry && _contentBlocks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Linktree entries can only have one content block.')),
      );
      return;
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
    if (_overallTitleController.text.isEmpty) {
      // Overall title is now mandatory
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter an overall title for the entry.')),
      );
      return;
    }
    if (_contentBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot submit an empty blog entry. Add some content blocks first.')),
      );
      return;
    }

    // Special handling for Linktree: ensure only one content block and it has a link
    if (_isLinktreeEntry) {
      if (_contentBlocks.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Linktree entries should only have one content block.')),
        );
        return;
      }
      if (!_contentBlocks.first.hasLinkUrl() ||
          _contentBlocks.first.linkUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'The content block for a Linktree entry must have a Link URL.')),
        );
        return;
      }
    }

    String title = _overallTitleController.text;
    List<String> tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final blogEntry = BlogEntry();
    blogEntry.content.addAll(_contentBlocks);

    try {
      final String blogEntryJsonString = blogEntry.writeToJson();

      // Protobuf messages have a .writeToBuffer() method to serialize
      // Firestore can store bytes (Uint8List) using Blob type
      final Map<String, dynamic> dataToSave = {
        'title': title,
        'entry': blogEntryJsonString,
        'created': FieldValue.serverTimestamp(),
        'tags': tags,
      };

      DocumentReference docRef = await widget.db
          .collection(_isLinktreeEntry
              ? _selectedAppSection.linktreeCollection
              : _selectedAppSection.bloggingCollection)
          .add(dataToSave);
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
    _overallTitleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLinktreeEntry
            ? 'Author Controls - New Linktree Entry'
            : 'Author Controls - New Blog Entry'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Added to prevent overflow with more fields
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Entry Type Switches ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Target Section:'),
                      DropdownButton<AppSection>(
                        value: _selectedAppSection,
                        items: AppSection.values.map((AppSection section) {
                          return DropdownMenuItem<AppSection>(
                            value: section,
                            child: Text(section
                                .toString()
                                .split('.')
                                .last), // Display enum name
                          );
                        }).toList(),
                        onChanged: (AppSection? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedAppSection = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Entry Type:'),
                      Switch(
                        value: _isLinktreeEntry,
                        onChanged: (bool value) {
                          setState(() {
                            _isLinktreeEntry = value;
                            // If switching to linktree and there's more than one block,
                            // you might want to clear blocks or show a warning.
                            if (_isLinktreeEntry && _contentBlocks.length > 1) {
                              _contentBlocks
                                  .clear(); // Or just take the first one
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Linktree entries use only one content block. Existing blocks cleared/reduced.')),
                              );
                            }
                          });
                        },
                      ),
                      Text(_isLinktreeEntry ? 'Linktree' : 'Blog Post'),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1),

              // --- Overall Entry Details ---
              Text('Entry Details:',
                  style: Theme.of(context).textTheme.titleLarge),
              TextField(
                controller: _overallTitleController,
                decoration: const InputDecoration(
                    labelText: 'Overall Title (Required)'),
              ),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated, optional)'),
              ),
              const SizedBox(height: 20),

              // --- Content Block Section ---
              // Conditionally show content block fields based on entry type
              // For Linktree, the "Title" of the content block might be less relevant,
              // and the Link URL is primary. Image URL is also useful.
              Text(
                _isLinktreeEntry
                    ? 'Link Details (One Block Only):'
                    : 'New Content Block:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              // Optional: Hide Content Block Title if it's a Linktree entry and you want to simplify
              // if (!_isLinktreeEntry)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                    labelText: _isLinktreeEntry
                        ? 'Display Text (Optional)'
                        : 'Content Block Title (Optional)'),
              ),
              TextField(
                controller: _linkUrlController,
                decoration: InputDecoration(
                    labelText: _isLinktreeEntry
                        ? 'Link URL (Required for Linktree)'
                        : 'Content Block Link URL (Optional)'),
              ),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                    labelText: 'Content Block Image URL (Optional)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box),
                label: Text(_isLinktreeEntry && _contentBlocks.isNotEmpty
                    ? 'Replace Link Details'
                    : 'Add Content Block'),
                onPressed: _addContentBlock,
                // Disable if it's linktree and a block already exists (unless you want "replace" functionality)
                // style: ElevatedButton.styleFrom(
                //   primary: (_isLinktreeEntry && _contentBlocks.isNotEmpty) ? Colors.grey : null,
                // ),
              ),
              const SizedBox(height: 20),

              Text('Current Content Blocks (${_contentBlocks.length}):',
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              _contentBlocks.isEmpty
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No content blocks added yet.'),
                    ))
                  : ListView.builder(
                      shrinkWrap: true,
                      // Important inside SingleChildScrollView
                      physics: const NeverScrollableScrollPhysics(),
                      // Important inside SingleChildScrollView
                      itemCount: _contentBlocks.length,
                      itemBuilder: (context, index) {
                        final block = _contentBlocks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                                block.hasTitle() ? block.title : 'No Title'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (block.hasLinkUrl())
                                  Text('Link: ${block.linkUrl}'),
                                if (block.hasImageUrl())
                                  Text('Image: ${block.imageUrl}'),
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
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Submit Entry'),
                  onPressed: _submitBlogEntry, // No longer passes appSection
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
