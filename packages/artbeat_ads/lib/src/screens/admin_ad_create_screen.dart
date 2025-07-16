import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ad_model.dart';
import '../models/ad_type.dart' as model;
import '../models/ad_location.dart' as model;
import '../models/ad_duration.dart';
import '../models/ad_status.dart';
import '../services/ad_service.dart';
import '../widgets/ad_type_picker_widget.dart';
import '../widgets/ad_location_picker_widget.dart';
import '../widgets/ad_duration_picker_widget.dart';
import '../widgets/ad_payment_widget.dart';
import '../widgets/ad_display_widget.dart';

class AdminAdCreateScreen extends StatefulWidget {
  const AdminAdCreateScreen({super.key});

  @override
  State<AdminAdCreateScreen> createState() => _AdminAdCreateScreenState();
}

class _AdminAdCreateScreenState extends State<AdminAdCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _imageFile;
  model.AdType _adType = model.AdType.square;
  model.AdLocation _adLocation = model.AdLocation.home;
  int _durationDays = 7;
  double _pricePerDay = 15.0;
  bool _isProcessing = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fileName =
          'ads/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void _submitAd() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) return;
    setState(() => _isProcessing = true);
    try {
      // Upload image and get URL
      final imageUrl = await _uploadImage(File(_imageFile!.path));

      // Get current user ID from auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ad = AdModel(
        id: '',
        ownerId: user.uid,
        type: _adType,
        imageUrl: imageUrl,
        title: _titleController.text,
        description: _descController.text,
        location: _adLocation,
        duration: AdDuration(days: _durationDays),
        pricePerDay: _pricePerDay,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: _durationDays)),
        status: AdStatus.pending,
      );
      final service = AdService();
      await service.createAd(ad);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad submitted for approval!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin Ad'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF8FBFF),
              Color(0xFFE1F5FE),
              Color(0xFFBBDEFB),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ad Image',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: _imageFile == null
                        ? Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Text('Tap to select image'),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_imageFile!.path),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Ad Title'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Description',
                    ),
                    maxLines: 3,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  AdTypePickerWidget(
                    selectedType: _adType,
                    onChanged: (type) => setState(() => _adType = type),
                  ),
                  const SizedBox(height: 12),
                  AdLocationPickerWidget(
                    selectedLocation: _adLocation,
                    availableLocations: model.AdLocation.values,
                    onChanged: (loc) => setState(() => _adLocation = loc),
                  ),
                  const SizedBox(height: 12),
                  AdDurationPickerWidget(
                    selectedDays: _durationDays,
                    onChanged: (days) => setState(() => _durationDays = days),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Price per day:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _pricePerDay.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(prefixText: '\t'),
                          onChanged: (v) {
                            final val = double.tryParse(v);
                            if (val != null) setState(() => _pricePerDay = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AdPaymentWidget(
                    days: _durationDays,
                    pricePerDay: _pricePerDay,
                    onPay: _submitAd,
                    isProcessing: _isProcessing,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  AdDisplayWidget(
                    imageUrl: _imageFile?.path ?? '',
                    title: _titleController.text,
                    description: _descController.text,
                    displayType: _adType == model.AdType.square
                        ? AdDisplayType.square
                        : AdDisplayType.rectangle,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
