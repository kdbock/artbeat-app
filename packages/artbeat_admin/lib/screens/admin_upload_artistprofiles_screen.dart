import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Admin screen for uploading artist profiles (bypasses all limits/approvals)
class AdminUploadArtistProfilesScreen extends StatefulWidget {
  const AdminUploadArtistProfilesScreen({super.key});

  @override
  State<AdminUploadArtistProfilesScreen> createState() =>
      _AdminUploadArtistProfilesScreenState();
}

class _AdminUploadArtistProfilesScreenState
    extends State<AdminUploadArtistProfilesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  List<String> _tags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a profile image')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        final ref = _storage.ref().child(
            'artist_profiles/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }
      final userId = _auth.currentUser?.uid ?? 'admin';
      await _firestore.collection('artistProfiles').add({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'website': _websiteController.text.trim(),
        'location': _locationController.text.trim(),
        'tags': _tags,
        'imageUrl': imageUrl,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'adminUpload': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Artist profile uploaded successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading profile: $e')));
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
      appBar: AppBar(title: const Text('Admin Upload Artist Profiles')),
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
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(labelText: 'Website'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
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
                        onPressed: _isLoading ? null : _saveProfile,
                        child: const Text('Upload Artist Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
