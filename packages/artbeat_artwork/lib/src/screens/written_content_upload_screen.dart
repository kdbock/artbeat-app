import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        ArtbeatColors,
        EnhancedUniversalHeader,
        MainLayout,
        AppLogger;
import 'package:artbeat_artwork/artbeat_artwork.dart'
    show ArtworkService, ChapterService;

// Rich text editing imports
import 'package:flutter_markdown/flutter_markdown.dart';

class WrittenContentUploadScreen extends StatefulWidget {
  final String? contentId;

  const WrittenContentUploadScreen({
    super.key,
    this.contentId,
  });

  @override
  State<WrittenContentUploadScreen> createState() =>
      _WrittenContentUploadScreenState();
}

class _WrittenContentUploadScreenState
    extends State<WrittenContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _tagController;
  late final TextEditingController _authorNoteController;
  late final TextEditingController _chaptersController;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Services
  final ArtworkService _artworkService = ArtworkService();
  final ChapterService _chapterService = ChapterService();

  File? _coverImageFile;
  bool _isForSale = false;
  bool _isSerialized = false;
  bool _isSaving = false;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  final List<String> _genres = [];
  final List<String> _tags = [];
  String _contentType = 'Book';
  int _totalChaptersPlanned = 1;
  String _releaseSchedule = 'immediate';

  // Content management
  File? _contentFile;
  String _contentText = '';
  bool _useFileUpload = true; // true for file upload, false for text input
  bool _useRichText = false; // true for rich text editor, false for plain text
  List<Map<String, dynamic>> _chapters = []; // For serialized content

  // Rich text editor (markdown-based)
  final TextEditingController _richTextController = TextEditingController();
  bool _showPreview = false;

  // Validation
  int _wordCount = 0;
  int _estimatedReadingTime = 0;
  bool _isValidContent = false;

  final List<String> _availableGenres = [
    'Fiction',
    'Non-Fiction',
    'Romance',
    'Mystery',
    'Thriller',
    'Science Fiction',
    'Fantasy',
    'Horror',
    'Poetry',
    'Essay',
    'Biography',
    'Self-Help',
    'Children',
    'Young Adult',
  ];

  final List<String> _contentTypes = [
    'Book',
    'Serial Story',
    'Webtoon',
    'Audiobook'
  ];
  final List<String> _releaseSchedules = [
    'immediate',
    'weekly',
    'bi-weekly',
    'monthly',
    'custom'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _tagController = TextEditingController();
    _authorNoteController = TextEditingController();
    _chaptersController = TextEditingController(text: '1');

    // Initialize rich text controller
    _richTextController.addListener(_onRichTextChanged);

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!mounted) return;

      setState(() {
        _tierLevel = SubscriptionTier.values.firstWhere(
          (tier) => tier.name == userDoc.get('subscriptionTier'),
          orElse: () => SubscriptionTier.free,
        );
      });

      final artworkDocs = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _artworkCount = artworkDocs.count ?? 0;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user data: $e');
    }
  }

  bool get _canUpload {
    int limit = 3;
    switch (_tierLevel) {
      case SubscriptionTier.free:
        limit = 3;
        break;
      case SubscriptionTier.starter:
        limit = 25;
        break;
      case SubscriptionTier.creator:
        limit = 100;
        break;
      case SubscriptionTier.business:
      case SubscriptionTier.enterprise:
        limit = 999999;
        break;
      default:
        limit = 3;
    }
    return _artworkCount < limit;
  }

  // Content management methods
  Future<void> _selectContentFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _contentFile = File(result.files.single.path!);
          _contentText = '';
        });
        await _processContentFile();
      }
    } catch (e) {
      AppLogger.error('Error selecting content file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('written_content_upload_file_error'
                  .tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _processContentFile() async {
    if (_contentFile == null) return;

    try {
      String content = await _contentFile!.readAsString();
      await _validateAndProcessContent(content);
    } catch (e) {
      AppLogger.error('Error processing content file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('written_content_upload_process_error'
                  .tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _validateAndProcessContent(String content) async {
    // Basic validation
    if (content.trim().isEmpty) {
      setState(() => _isValidContent = false);
      return;
    }

    // Calculate word count and reading time
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final wordCount = words.length;
    final readingTime = (wordCount / 200).ceil(); // ~200 words per minute

    // Plagiarism prevention: Check for duplicate content
    final contentHash = _generateContentHash(content);
    final isDuplicate = await _checkForDuplicateContent(contentHash);

    setState(() {
      _wordCount = wordCount;
      _estimatedReadingTime = readingTime;
      _isValidContent = !isDuplicate && wordCount > 10; // Minimum 10 words
      if (_useFileUpload) {
        _contentText = content;
      }
    });

    if (isDuplicate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('written_content_upload_duplicate_warning'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _generateContentHash(String content) {
    // Simple hash for duplicate detection
    return content.hashCode.toString();
  }

  Future<bool> _checkForDuplicateContent(String contentHash) async {
    try {
      // Check recent uploads for similar content
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final recentArtworks = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .where('contentType', isEqualTo: 'written')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (final doc in recentArtworks.docs) {
        final existingHash = doc.data()['contentHash'];
        if (existingHash == contentHash) {
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Error checking for duplicate content: $e');
      return false;
    }
  }

  void _toggleContentInputMode() {
    setState(() {
      _useFileUpload = !_useFileUpload;
      if (_useFileUpload) {
        _contentText = '';
      } else {
        _contentFile = null;
      }
      _isValidContent = false;
    });
  }

  void _toggleRichTextMode() {
    setState(() {
      _useRichText = !_useRichText;
      if (_useRichText) {
        // Switch to rich text mode - copy content to rich text controller
        _richTextController.text = _contentText;
      } else {
        // Switch to plain text mode - copy content back
        _contentText = _richTextController.text;
      }
    });
  }

  void _onRichTextChanged() {
    if (_useRichText) {
      _contentText = _richTextController.text;
      _validateAndProcessContent(_contentText);
    }
  }

  void _insertMarkdownFormatting(String prefix, String suffix) {
    final controller = _richTextController;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final beforeText = text.substring(0, selection.start);
    final selectedText = text.substring(selection.start, selection.end);
    final afterText = text.substring(selection.end);

    final newText = '$beforeText$prefix$selectedText$suffix$afterText';
    controller.text = newText;

    // Update cursor position
    final newCursorPos =
        selection.start + prefix.length + selectedText.length + suffix.length;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  Future<void> _splitContentIntoChapters() async {
    if (!_isSerialized || _contentText.isEmpty) return;

    final content = _contentText;
    final chapterMarkers =
        RegExp(r'#{1,2}\s+Chapter\s+\d+', caseSensitive: false);
    final matches = chapterMarkers.allMatches(content);

    if (matches.isEmpty) {
      // No chapter markers found, split by paragraphs or create single chapter
      _chapters = [
        {
          'number': 1,
          'title': 'Chapter 1',
          'content': content,
          'wordCount': _wordCount,
          'readingTime': _estimatedReadingTime,
        }
      ];
    } else {
      // Split by chapter markers
      final List<Map<String, dynamic>> chapters = [];

      for (int i = 0; i < matches.length; i++) {
        final match = matches.elementAt(i);
        final nextMatch =
            i < matches.length - 1 ? matches.elementAt(i + 1) : null;

        final chapterStart = match.start;
        final chapterEnd = nextMatch?.start ?? content.length;

        final chapterContent =
            content.substring(chapterStart, chapterEnd).trim();
        final chapterTitle = match.group(0) ?? 'Chapter ${i + 1}';

        final words =
            chapterContent.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        final wordCount = words.length;
        final readingTime = (wordCount / 200).ceil();

        chapters.add({
          'number': i + 1,
          'title': chapterTitle,
          'content': chapterContent,
          'wordCount': wordCount,
          'readingTime': readingTime,
        });
      }

      _chapters = chapters;
    }

    setState(() {});
  }

  Future<void> _selectCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _coverImageFile = File(image.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error selecting cover image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('written_content_upload_image_error'
                  .tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _uploadContent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coverImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('written_content_upload_no_image_error'.tr())),
      );
      return;
    }

    if (!_isValidContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('written_content_upload_invalid_content'.tr())),
      );
      return;
    }

    if (!_canUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'written_content_upload_limit'.tr(),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      // Create artwork using ArtworkService
      final artworkId = await _artworkService.uploadArtwork(
        imageFile: _coverImageFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        medium: 'Written Work',
        styles: _genres,
        tags: _tags,
        price: _isForSale ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        isForSale: _isForSale,
      );

      // Update artwork metadata for written content
      final artwork = await _artworkService.getArtworkById(artworkId);
      if (artwork != null) {
        final updatedData = {
          'contentType': 'written',
          'isSerializing': _isSerialized,
          'totalChapters': _isSerialized ? _totalChaptersPlanned : 1,
          'releasedChapters': 0,
          'readingMetadata': {
            'wordCount': _wordCount,
            'estimatedReadingTime': _estimatedReadingTime,
            'language': 'en',
            'contentFormat': _useFileUpload ? 'file' : 'text',
          },
          'serializationConfig': _isSerialized
              ? {
                  'releaseSchedule': _releaseSchedule,
                  'startDate': DateTime.now().toIso8601String(),
                }
              : null,
          'contentHash': _generateContentHash(_contentText),
          'authorNote': _authorNoteController.text,
        };

        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .update(updatedData);
      }

      // Create chapters
      if (_isSerialized && _chapters.isNotEmpty) {
        await _createChaptersForArtwork(artworkId);
      } else if (!_isSerialized) {
        // Create single chapter for complete work
        await _chapterService.createChapter(
          artworkId: artworkId,
          chapterNumber: 1,
          title: _titleController.text,
          description: _descriptionController.text,
          content: _contentText,
          estimatedReadingTime: _estimatedReadingTime,
          wordCount: _wordCount,
          releaseDate: DateTime.now(),
          tags: _tags,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('written_content_upload_success'.tr())),
        );
        Navigator.of(context).pop(artworkId);
      }
    } catch (e) {
      AppLogger.error('Error uploading content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'written_content_upload_error'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _createChaptersForArtwork(String artworkId) async {
    if (_chapters.isEmpty) return;

    for (final chapter in _chapters) {
      await _chapterService.createChapter(
        artworkId: artworkId,
        chapterNumber: chapter['number'] as int,
        title: chapter['title'] as String,
        description: (chapter['content'] as String)
            .substring(0, 100.clamp(0, (chapter['content'] as String).length)),
        content: chapter['content'] as String,
        estimatedReadingTime: chapter['readingTime'] as int,
        wordCount: chapter['wordCount'] as int,
        releaseDate: DateTime.now()
            .add(Duration(days: 7 * ((chapter['number'] as int) - 1))),
        tags: _tags,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'written_content_upload_title'.tr(),
          showLogo: false,
          showBackButton: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_canUpload)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'written_content_upload_limit'.tr(),
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                Text(
                  'written_content_upload_content_type_label'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _contentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelText: 'written_content_upload_content_type_label'.tr(),
                    labelStyle: const TextStyle(color: Colors.black87),
                  ),
                  style: const TextStyle(color: Colors.black87),
                  items: _contentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _contentType = value ?? 'Book';
                    });
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'written_content_upload_content_section'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // Content input mode toggle
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleContentInputMode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _useFileUpload
                              ? ArtbeatColors.primaryGreen
                              : Colors.grey,
                        ),
                        child: Text('written_content_upload_file_mode'.tr()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleContentInputMode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_useFileUpload
                              ? ArtbeatColors.primaryGreen
                              : Colors.grey,
                        ),
                        child: Text('written_content_upload_text_mode'.tr()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Rich text toggle (only show when in text mode)
                if (!_useFileUpload) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _toggleRichTextMode,
                      icon: Icon(
                          _useRichText ? Icons.text_fields : Icons.format_bold),
                      label: Text(_useRichText
                          ? 'written_content_upload_plain_text_mode'.tr()
                          : 'written_content_upload_rich_text_mode'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _useRichText
                            ? ArtbeatColors.primaryGreen
                            : Colors.grey[300],
                        foregroundColor:
                            _useRichText ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Content input area
                if (_useFileUpload) ...[
                  GestureDetector(
                    onTap: _selectContentFile,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _contentFile != null
                              ? ArtbeatColors.primaryGreen
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _contentFile != null
                                  ? Icons.file_present
                                  : Icons.file_upload,
                              size: 32,
                              color: _contentFile != null
                                  ? ArtbeatColors.primaryGreen
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _contentFile != null
                                  ? _contentFile!.path.split('/').last
                                  : 'written_content_upload_select_file'.tr(),
                              style: TextStyle(
                                color: _contentFile != null
                                    ? ArtbeatColors.primaryGreen
                                    : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  if (_useRichText) ...[
                    // Rich text editor (markdown-based)
                    Column(
                      children: [
                        // Formatting toolbar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.format_bold),
                                onPressed: () =>
                                    _insertMarkdownFormatting('**', '**'),
                                tooltip: 'Bold',
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_italic),
                                onPressed: () =>
                                    _insertMarkdownFormatting('*', '*'),
                                tooltip: 'Italic',
                              ),
                              IconButton(
                                icon: const Icon(Icons.title),
                                onPressed: () =>
                                    _insertMarkdownFormatting('# ', ''),
                                tooltip: 'Header',
                              ),
                              IconButton(
                                icon: const Icon(Icons.link),
                                onPressed: () =>
                                    _insertMarkdownFormatting('[', '](url)'),
                                tooltip: 'Link',
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(
                                    _showPreview ? Icons.edit : Icons.preview),
                                onPressed: _togglePreview,
                                tooltip: _showPreview ? 'Edit' : 'Preview',
                              ),
                            ],
                          ),
                        ),
                        // Editor/Preview area
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: _showPreview
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: MarkdownBody(
                                    data: _richTextController.text,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(fontSize: 16),
                                      h1: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                      h2: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                      h3: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      strong: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      em: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                )
                              : TextField(
                                  controller: _richTextController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(16),
                                    border: InputBorder.none,
                                    hintText:
                                        'Start writing your story... Use markdown for formatting',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Plain text editor
                    TextFormField(
                      initialValue: _contentText,
                      onChanged: (value) {
                        _contentText = value;
                        _validateAndProcessContent(value);
                      },
                      decoration: InputDecoration(
                        labelText: 'written_content_upload_content_label'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'written_content_upload_content_hint'.tr(),
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if ((value?.isEmpty ?? true) && !_useFileUpload) {
                          return 'written_content_upload_content_required'.tr();
                        }
                        return null;
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                // Content validation info
                if (_contentText.isNotEmpty || _contentFile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isValidContent
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isValidContent ? Colors.green : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isValidContent
                              ? 'written_content_upload_validation_passed'.tr()
                              : 'written_content_upload_validation_failed'.tr(),
                          style: TextStyle(
                            color: _isValidContent ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'written_content_upload_stats'.tr(args: [
                            _wordCount.toString(),
                            _estimatedReadingTime.toString()
                          ]),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final content =
                                _useFileUpload ? _contentText : _contentText;
                            if (content.isNotEmpty) {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                      'written_content_upload_preview_title'
                                          .tr()),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    height: 400,
                                    child: SingleChildScrollView(
                                      child: Text(
                                        content,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('close'.tr()),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.preview),
                          label: Text('written_content_upload_preview'.tr()),
                        ),
                      ),
                      if (_isSerialized) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _splitContentIntoChapters,
                            icon: const Icon(Icons.call_split),
                            label: Text(
                                'written_content_upload_split_chapters'.tr()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectCoverImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: ArtbeatColors.primaryGreen,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _coverImageFile != null
                        ? Image.file(
                            _coverImageFile!,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: ArtbeatColors.primaryGreen,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'written_content_upload_cover_image_hint'
                                      .tr(),
                                  style: const TextStyle(
                                    color: ArtbeatColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'written_content_upload_title_label'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'written_content_upload_title_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'written_content_upload_description_label'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'written_content_upload_description_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authorNoteController,
                  decoration: InputDecoration(
                    labelText: 'written_content_upload_author_note_label'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'written_content_upload_genres_label'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableGenres.map((genre) {
                    final isSelected = _genres.contains(genre);
                    return FilterChip(
                      label: Text(genre),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _genres.add(genre);
                          } else {
                            _genres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  title:
                      Text('written_content_upload_serialized_checkbox'.tr()),
                  subtitle: Text('written_content_upload_serialized_hint'.tr()),
                  value: _isSerialized,
                  onChanged: (value) {
                    setState(() {
                      _isSerialized = value ?? false;
                    });
                  },
                ),
                if (_isSerialized) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _chaptersController,
                    decoration: InputDecoration(
                      labelText: 'written_content_upload_chapters_label'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _totalChaptersPlanned = int.tryParse(value) ?? 1;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'written_content_upload_schedule_label'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _releaseSchedule,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelText: 'written_content_upload_schedule_label'.tr(),
                      labelStyle: const TextStyle(color: Colors.black87),
                    ),
                    style: const TextStyle(color: Colors.black87),
                    items: _releaseSchedules.map((schedule) {
                      return DropdownMenuItem(
                        value: schedule,
                        child:
                            Text(schedule.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _releaseSchedule = value ?? 'immediate';
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                CheckboxListTile(
                  title: Text('written_content_upload_for_sale_checkbox'.tr()),
                  value: _isForSale,
                  onChanged: (value) {
                    setState(() {
                      _isForSale = value ?? false;
                    });
                  },
                ),
                if (_isForSale) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'written_content_upload_price_label'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_isForSale && (value?.isEmpty ?? true)) {
                        return 'written_content_upload_price_required'.tr();
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || !_canUpload ? null : _uploadContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('written_content_upload_button'.tr()),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagController.dispose();
    _authorNoteController.dispose();
    _chaptersController.dispose();
    super.dispose();
  }
}
