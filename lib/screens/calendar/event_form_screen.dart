import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artbeat/services/event_service.dart';

/// Screen for creating or editing events
class EventFormScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String?
      eventId; // Optional, only provided when editing an existing event

  const EventFormScreen({
    super.key,
    required this.selectedDate,
    this.eventId,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // Form state
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  bool _isPublic = false;
  File? _imageFile;
  String _existingImageUrl = '';

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate;
    _isEditMode = widget.eventId != null;

    if (_isEditMode) {
      _loadEventData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Load existing event data when in edit mode
  Future<void> _loadEventData() async {
    if (widget.eventId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final event = await _eventService.getEventById(widget.eventId!);

      if (event != null) {
        setState(() {
          _titleController.text = event.title;
          _descriptionController.text = event.description;
          _locationController.text = event.location;
          _date = event.date;
          _startTime = event.startTime;
          _endTime = event.endTime;
          _isPublic = event.isPublic;
          _existingImageUrl = event.imageUrl;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading event: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Select date for event
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != _date) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  // Select start time for event
  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime != null && pickedTime != _startTime) {
      setState(() {
        _startTime = pickedTime;

        // If end time is before start time, reset it
        if (_endTime != null) {
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
          if (endMinutes <= startMinutes) {
            _endTime = null;
          }
        }
      });
    }
  }

  // Select end time for event
  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime ??
          TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          ),
    );

    if (pickedTime != null) {
      // Validate that end time is after start time
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = pickedTime.hour * 60 + pickedTime.minute;

      if (endMinutes <= startMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
        }
        return;
      }

      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  // Clear selected end time
  void _clearEndTime() {
    setState(() {
      _endTime = null;
    });
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _eventService.pickEventImage(fromCamera: false);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _eventService.pickEventImage(fromCamera: true);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: ${e.toString()}')),
        );
      }
    }
  }

  // Show dialog to select image source
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_imageFile != null || _existingImageUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imageFile = null;
                    _existingImageUrl = '';
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // Save the event
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final location = _locationController.text.trim();

      if (_isEditMode && widget.eventId != null) {
        // Update existing event
        await _eventService.updateEvent(
          eventId: widget.eventId!,
          title: title,
          description: description,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          location: location,
          isPublic: _isPublic,
          imageFile: _imageFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new event
        await _eventService.createEvent(
          title: title,
          description: description,
          date: _date,
          startTime: _startTime,
          endTime: _endTime,
          location: location,
          isPublic: _isPublic,
          imageFile: _imageFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Event' : 'Create Event'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'Delete Event',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStartTimeField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEndTimeField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLocationField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 24),
                    _buildIsPublicSwitch(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditMode ? 'UPDATE EVENT' : 'CREATE EVENT',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          image: _imageFile != null
              ? DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : _existingImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_existingImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: _imageFile == null && _existingImageUrl.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Add Event Image',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white70,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black87),
                      onPressed: _showImageSourceDialog,
                      tooltip: 'Change Image',
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Event Title',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.event),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event title';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat.yMMMMd().format(_date)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTimeField() {
    return InkWell(
      onTap: _selectStartTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Start Time',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.access_time),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_startTime.format(context)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildEndTimeField() {
    return InkWell(
      onTap: _selectEndTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'End Time (Optional)',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.access_time),
          suffixIcon: _endTime != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearEndTime,
                  tooltip: 'Clear End Time',
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_endTime?.format(context) ?? 'Not Set'),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: const InputDecoration(
        labelText: 'Location',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a location';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildIsPublicSwitch() {
    return SwitchListTile(
      title: const Text('Show on Community Calendar'),
      subtitle: const Text(
        'Make this event visible to all WordNerd users',
      ),
      value: _isPublic,
      onChanged: (value) {
        setState(() {
          _isPublic = value;
        });
      },
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.eventId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _eventService.deleteEvent(widget.eventId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: ${e.toString()}')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
