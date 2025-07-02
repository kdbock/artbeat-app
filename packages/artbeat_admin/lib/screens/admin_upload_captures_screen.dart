import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show UniversalHeader, MainLayout;

/// Admin screen for uploading captures (bypasses all limits/approvals)
class AdminUploadCapturesScreen extends StatefulWidget {
  const AdminUploadCapturesScreen({super.key});

  @override
  State<AdminUploadCapturesScreen> createState() =>
      _AdminUploadCapturesScreenState();
}

class _AdminUploadCapturesScreenState extends State<AdminUploadCapturesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
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

  Future<void> _saveCapture() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        final ref = _storage.ref().child(
            'captures/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.path.split('/').last}');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }
      final userId = _auth.currentUser?.uid ?? 'admin';
      await _firestore.collection('captures').add({
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrl': imageUrl,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'adminUpload': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Capture uploaded successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading capture: $e')));
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
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const UniversalHeader(
          title: 'Admin Upload Captures',
          showLogo: false,
        ),
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
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _imageFile != null
                              ? Image.file(_imageFile!,
                                  width: 100, height: 100, fit: BoxFit.cover)
                              : _imageUrl != null
                                  ? Image.network(_imageUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover)
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
                          onPressed: _isLoading ? null : _saveCapture,
                          child: const Text('Upload Capture'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
