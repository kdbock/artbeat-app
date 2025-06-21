import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin screen for uploading artwork (bypasses all limits/approvals)
class AdminUploadArtworksScreen extends StatefulWidget {
  const AdminUploadArtworksScreen({super.key});

  @override
  State<AdminUploadArtworksScreen> createState() =>
      _AdminUploadArtworksScreenState();
}

class _AdminUploadArtworksScreenState extends State<AdminUploadArtworksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagController = TextEditingController();

  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  File? _imageFile;
  String? _imageUrl;
  bool _isForSale = false;
  bool _isLoading = false;
  String _medium = '';
  List<String> _styles = [];
  List<String> _tags = [];

  final List<String> _availableMediums = [
    'Oil Paint',
    'Acrylic',
    'Watercolor',
    'Charcoal',
    'Pastel',
    'Digital',
    'Mixed Media',
    'Sculpture',
    'Photography',
    'Textiles',
    'Ceramics',
    'Printmaking',
    'Pen & Ink',
    'Pencil'
  ];
  final List<String> _availableStyles = [
    'Abstract',
    'Realism',
    'Impressionism',
    'Expressionism',
    'Minimalism',
    'Pop Art',
    'Surrealism',
    'Cubism',
    'Contemporary',
    'Folk Art',
    'Street Art',
    'Illustration',
    'Fantasy',
    'Portrait'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    _materialsController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _yearController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')));
      return;
    }
    if (_medium.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a medium')));
      return;
    }
    if (_styles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one style')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        final ref = _storage.ref().child(
            'artwork/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }
      final userId = _auth.currentUser?.uid ?? 'admin';
      await _firestore.collection('artwork').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dimensions': _dimensionsController.text.trim(),
        'materials': _materialsController.text.trim(),
        'location': _locationController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'yearCreated': int.tryParse(_yearController.text.trim()),
        'imageUrl': imageUrl,
        'isForSale': _isForSale,
        'medium': _medium,
        'styles': _styles,
        'tags': _tags,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'adminUpload': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork uploaded successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading artwork: $e')));
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Upload Artworks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dimensionsController,
                      decoration:
                          const InputDecoration(labelText: 'Dimensions'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materialsController,
                      decoration: const InputDecoration(labelText: 'Materials'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _yearController,
                      decoration:
                          const InputDecoration(labelText: 'Year Created'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _medium.isNotEmpty ? _medium : null,
                      items: _availableMediums
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _medium = v ?? ''),
                      decoration: const InputDecoration(labelText: 'Medium'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Styles'),
                      child: Wrap(
                        spacing: 8,
                        children: _availableStyles.map((style) {
                          final selected = _styles.contains(style);
                          return FilterChip(
                            label: Text(style),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _styles.add(style);
                                } else {
                                  _styles.remove(style);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)'),
                      onChanged: (v) => setState(() => _tags = v
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _isForSale,
                          onChanged: (v) =>
                              setState(() => _isForSale = v ?? false),
                        ),
                        const Text('For Sale'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _imageFile != null
                            ? Image.file(_imageFile!,
                                width: 100, height: 100, fit: BoxFit.cover)
                            : _imageUrl != null
                                ? Image.network(_imageUrl!,
                                    width: 100, height: 100, fit: BoxFit.cover)
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 40)),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload),
                          label: const Text('Select Image'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveArtwork,
                        child: const Text('Upload Artwork'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
