import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../models/refund_policy.dart';
import '../widgets/ticket_type_builder.dart';

/// Form builder for creating and editing ARTbeat events
/// Includes all required fields from the specification
class EventFormBuilder extends StatefulWidget {
  final ArtbeatEvent? initialEvent;
  final Function(ArtbeatEvent) onEventCreated;
  final VoidCallback? onCancel;
  final bool useUniversalHeader;

  const EventFormBuilder({
    super.key,
    this.initialEvent,
    required this.onEventCreated,
    this.onCancel,
    this.useUniversalHeader = false,
  });

  @override
  State<EventFormBuilder> createState() => _EventFormBuilderState();
}

class _EventFormBuilderState extends State<EventFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  DateTime? _selectedDateTime;
  final List<File> _eventImages = [];
  File? _artistHeadshot;
  File? _eventBanner;
  List<TicketType> _ticketTypes = [];
  RefundPolicy _refundPolicy = RefundPolicy.standard();
  bool _isPublic = true;
  bool _reminderEnabled = true;
  List<String> _tags = [];
  final List<String> _availableTags = [
    'Art Exhibition',
    'Gallery Opening',
    'Workshop',
    'Artist Talk',
    'Live Performance',
    'Interactive Art',
    'Sculpture',
    'Painting',
    'Photography',
    'Digital Art',
    'Mixed Media',
    'Contemporary Art',
    'Abstract Art',
    'Pop Art',
    'Street Art',
    'Installation',
    'Art Fair',
    'Community Event',
    'Educational',
    'Networking',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialEvent != null) {
      final event = widget.initialEvent!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _contactEmailController.text = event.contactEmail;
      _contactPhoneController.text = event.contactPhone ?? '';
      _maxAttendeesController.text = event.maxAttendees.toString();
      _selectedDateTime = event.dateTime;
      _ticketTypes = List.from(event.ticketTypes);
      _refundPolicy = event.refundPolicy;
      _isPublic = event.isPublic;
      _reminderEnabled = event.reminderEnabled;
      _tags = List.from(event.tags);
    } else {
      _maxAttendeesController.text = '100';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useUniversalHeader
          ? UniversalHeader(
              title:
                  widget.initialEvent == null ? 'Create Event' : 'Edit Event',
              showLogo: false,
              actions: [
                TextButton(
                  onPressed: _submitForm,
                  child: const Text('Save'),
                ),
              ],
            )
          : AppBar(
              title: Text(
                  widget.initialEvent == null ? 'Create Event' : 'Edit Event'),
              actions: [
                TextButton(
                  onPressed: _submitForm,
                  child: const Text('Save'),
                ),
              ],
            ),
      body: Container(
        decoration: widget.useUniversalHeader
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple.withAlpha(25),
                    ArtbeatColors.backgroundPrimary,
                    ArtbeatColors.primaryGreen.withAlpha(25),
                  ],
                ),
              )
            : null,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 20),
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildDateTimeSection(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 20),
                _buildContactSection(),
                const SizedBox(height: 20),
                _buildCapacitySection(),
                const SizedBox(height: 20),
                _buildTagsSection(),
                const SizedBox(height: 20),
                _buildTicketTypesSection(),
                const SizedBox(height: 20),
                _buildRefundPolicySection(),
                const SizedBox(height: 20),
                _buildSettingsSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtbeatColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Event Title *',
              hintText: 'Enter event title',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an event title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Event Description *',
              hintText: 'Describe your event in detail',
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an event description';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Images *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Artist Headshot
            _buildImageUploadSection(
              title: 'Artist Headshot *',
              image: _artistHeadshot,
              onImageSelected: (file) => setState(() => _artistHeadshot = file),
            ),
            const SizedBox(height: 16),

            // Event Banner
            _buildImageUploadSection(
              title: 'Event Banner *',
              image: _eventBanner,
              onImageSelected: (file) => setState(() => _eventBanner = file),
            ),
            const SizedBox(height: 16),

            // Additional Event Images
            const Text('Additional Event Images'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._eventImages.map((image) => _buildImagePreview(image, () {
                      setState(() => _eventImages.remove(image));
                    })),
                _buildAddImageButton(() async {
                  final image =
                      await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _eventImages.add(File(image.path)));
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required File? image,
    required Function(File?) onImageSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedImage =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (pickedImage != null) {
              onImageSelected(File(pickedImage.path));
            }
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey),
                      Text('Tap to select image'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(File image, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey),
            Text('Add', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDateTime != null
                  ? DateFormat('EEEE, MMMM d, y \'at\' h:mm a')
                      .format(_selectedDateTime!)
                  : 'Select date and time *'),
              onTap: _selectDateTime,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Event Location *',
                hintText: 'Enter venue address or location',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter event location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(
                labelText: 'Contact Email *',
                hintText: 'Enter contact email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter contact email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone (Optional)',
                hintText: 'Enter contact phone number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Capacity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxAttendeesController,
              decoration: const InputDecoration(
                labelText: 'Maximum Attendees *',
                hintText: 'Enter maximum number of attendees',
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter maximum attendees';
                }
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ticket Types',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addTicketType,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ticket'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ticketTypes.isEmpty)
              const Text(
                  'No ticket types added yet. Add at least one ticket type.')
            else
              ..._ticketTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final ticket = entry.value;
                return TicketTypeBuilder(
                  ticketType: ticket,
                  onChanged: (updatedTicket) {
                    setState(() {
                      _ticketTypes[index] = updatedTicket;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _ticketTypes.removeAt(index);
                    });
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundPolicySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Refund Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _getRefundPolicyKey(),
              decoration: const InputDecoration(
                labelText: 'Refund Policy',
                filled: true,
                fillColor:
                    ArtbeatColors.backgroundPrimary, // match login_screen
                border: OutlineInputBorder(),
              ),
              dropdownColor:
                  ArtbeatColors.backgroundPrimary, // match login_screen
              style: const TextStyle(color: Colors.black),
              items: const [
                DropdownMenuItem(
                    value: 'standard',
                    child: Text('Standard (24 hours)',
                        style: TextStyle(color: Colors.black))),
                DropdownMenuItem(
                    value: 'flexible',
                    child: Text('Flexible (7 days)',
                        style: TextStyle(color: Colors.black))),
                DropdownMenuItem(
                    value: 'no_refunds',
                    child: Text('No Refunds',
                        style: TextStyle(color: Colors.black))),
              ],
              onChanged: (value) {
                setState(() {
                  switch (value) {
                    case 'standard':
                      _refundPolicy = RefundPolicy.standard();
                      break;
                    case 'flexible':
                      _refundPolicy = RefundPolicy.flexible();
                      break;
                    case 'no_refunds':
                      _refundPolicy = RefundPolicy.noRefunds();
                      break;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _refundPolicy.fullDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public Event'),
              subtitle: const Text('Show event in community feed'),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Enable Reminders'),
              subtitle: const Text('Send reminder notifications to attendees'),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addTicketType() {
    // Add a default free ticket type
    final newTicket = TicketType.free(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'General Admission',
      quantity: 50,
    );

    setState(() {
      _ticketTypes.add(newTicket);
    });
  }

  String _getRefundPolicyKey() {
    if (_refundPolicy.fullRefundDeadline == const Duration(hours: 24)) {
      return 'standard';
    } else if (_refundPolicy.fullRefundDeadline == const Duration(days: 7)) {
      return 'flexible';
    } else {
      return 'no_refunds';
    }
  }

  // Helper to upload a file to Firebase Storage and get its download URL
  Future<String> _uploadImageToStorage(File file, String path) async {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date and time')),
      );
      return;
    }

    if (_artistHeadshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select artist headshot')),
      );
      return;
    }

    if (_eventBanner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event banner')),
      );
      return;
    }

    if (_ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ticket type')),
      );
      return;
    }

    // Upload images to Firebase Storage and get URLs
    // Get current user ID from UserService
    final userId = UserService().currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }
    final eventId = widget.initialEvent?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    String headshotUrl = '';
    String bannerUrl = '';
    List<String> imageUrls = [];
    try {
      headshotUrl = await _uploadImageToStorage(
          _artistHeadshot!, 'events/$userId/$eventId/headshot.jpg');
      bannerUrl = await _uploadImageToStorage(
          _eventBanner!, 'events/$userId/$eventId/banner.jpg');
      imageUrls = await Future.wait(_eventImages.asMap().entries.map((entry) =>
          _uploadImageToStorage(
              entry.value, 'events/$userId/$eventId/image_${entry.key}.jpg')));
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload images: $e')),
        );
      }
      return;
    }

    final event = widget.initialEvent?.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrls: imageUrls,
          artistHeadshotUrl: headshotUrl,
          eventBannerUrl: bannerUrl,
          dateTime: _selectedDateTime!,
          location: _locationController.text.trim(),
          ticketTypes: _ticketTypes,
          refundPolicy: _refundPolicy,
          reminderEnabled: _reminderEnabled,
          isPublic: _isPublic,
          maxAttendees: int.parse(_maxAttendeesController.text),
          tags: _tags,
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim().isEmpty
              ? null
              : _contactPhoneController.text.trim(),
        ) ??
        ArtbeatEvent.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          artistId: userId,
          imageUrls: imageUrls,
          artistHeadshotUrl: headshotUrl,
          eventBannerUrl: bannerUrl,
          dateTime: _selectedDateTime!,
          location: _locationController.text.trim(),
          ticketTypes: _ticketTypes,
          refundPolicy: _refundPolicy,
          reminderEnabled: _reminderEnabled,
          isPublic: _isPublic,
          maxAttendees: int.parse(_maxAttendeesController.text),
          tags: _tags,
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim().isEmpty
              ? null
              : _contactPhoneController.text.trim(),
        );

    widget.onEventCreated(event);
  }
}
