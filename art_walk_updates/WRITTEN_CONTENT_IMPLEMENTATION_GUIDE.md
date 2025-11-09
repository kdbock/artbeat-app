# Written Content & Serialized Works Implementation Guide

## Overview
This guide demonstrates how to implement written content (books, stories, comics) with serialization support in ArtBeat using the new models and services.

---

## 1. Upload Single Written Work (Book/Story)

### Example: Upload a Complete Novel

```dart
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart';

Future<void> uploadCompleteNovel() async {
  final artworkService = ArtworkService();
  final chapterService = ChapterService();
  
  try {
    // Step 1: Create base artwork entry
    final novelId = await artworkService.uploadArtwork(
      imageFile: File('path/to/book_cover.jpg'),
      title: 'The Last Journey',
      description: 'An epic fantasy novel about adventure and discovery',
      medium: 'Written Work',
      styles: ['Fantasy', 'Adventure', 'Epic'],
      tags: ['fantasy', 'epic', 'adventure'],
      price: 4.99,
      isForSale: true,
    );

    // Step 2: Update artwork metadata for written content
    final artwork = await artworkService.getArtworkById(novelId);
    final updatedArtwork = artwork?.copyWith(
      contentType: ArtworkContentType.written,
      isSerializing: false, // Complete work, not serialized
      readingMetadata: {
        'wordCount': 85000,
        'estimatedReadingTime': 250, // minutes
        'language': 'en',
        'contentFormat': 'plain_text',
      },
    );

    if (updatedArtwork != null) {
      await artworkService.updateArtwork(updatedArtwork);
    }

    // Step 3: Create chapters (all chapters of the book)
    final bookContent = await _loadBookFromFile('path/to/novel.txt');
    final chapters = _splitIntoChapters(bookContent);

    for (int i = 0; i < chapters.length; i++) {
      await chapterService.createChapter(
        artworkId: novelId,
        chapterNumber: i + 1,
        title: chapters[i]['title'],
        description: chapters[i]['description'],
        content: chapters[i]['content'],
        estimatedReadingTime: chapters[i]['readingTime'],
        wordCount: chapters[i]['wordCount'],
        releaseDate: DateTime.now(), // All chapters released immediately
        tags: ['chapter', 'part${i + 1}'],
      );
    }

    print('Novel uploaded successfully with ${chapters.length} chapters');
  } catch (e) {
    print('Error uploading novel: $e');
  }
}

// Helper: Split book content into chapters
List<Map<String, dynamic>> _splitIntoChapters(String fullText) {
  // Implement based on your book format
  // Example: split by "Chapter" markers
  final chapters = <Map<String, dynamic>>[];
  final chapterTexts = fullText.split(RegExp(r'#{1,2}\s+Chapter\s+\d+'));
  
  for (int i = 0; i < chapterTexts.length; i++) {
    final text = chapterTexts[i].trim();
    if (text.isEmpty) continue;
    
    chapters.add({
      'title': 'Chapter ${chapters.length + 1}',
      'description': text.substring(0, 100.clamp(0, text.length)),
      'content': text,
      'wordCount': text.split(' ').length,
      'readingTime': (text.split(' ').length / 200).ceil(), // ~200 words per minute
    });
  }
  return chapters;
}

Future<String> _loadBookFromFile(String path) async {
  final file = File(path);
  return await file.readAsString();
}
```

---

## 2. Upload Serialized Story (Chapter-by-Chapter Release)

### Example: Upload a Weekly Series

```dart
Future<void> uploadWeeklySeriesStory() async {
  final artworkService = ArtworkService();
  final chapterService = ChapterService();
  final scheduleService = ScheduleService();
  
  try {
    // Step 1: Create artwork entry for serialized story
    final storyId = await artworkService.uploadArtwork(
      imageFile: File('path/to/story_cover.jpg'),
      title: 'The Mysterious Island',
      description: 'A weekly mystery series with cliffhangers',
      medium: 'Written Work',
      styles: ['Mystery', 'Serial', 'Adventure'],
      tags: ['mystery', 'weekly', 'series'],
      price: 0.99, // Per-chapter price
      isForSale: true,
    );

    // Step 2: Mark as serialized
    final artwork = await artworkService.getArtworkById(storyId);
    final updatedArtwork = artwork?.copyWith(
      contentType: ArtworkContentType.written,
      isSerializing: true,
      totalChapters: 12, // Will have 12 chapters
      releasedChapters: 0,
      readingMetadata: {
        'wordCountPerChapter': 3000,
        'estimatedReadingTimePerChapter': 15,
        'language': 'en',
        'contentFormat': 'markdown',
      },
      serializationConfig: {
        'releaseSchedule': 'weekly',
        'startDate': DateTime.now().toIso8601String(),
        'dayOfWeek': 'Monday',
        'time': '10:00 AM',
      },
    );

    if (updatedArtwork != null) {
      await artworkService.updateArtwork(updatedArtwork);
    }

    // Step 3: Create all chapters
    final chapterIds = <String>[];
    final chapterTexts = await _loadAllChapters('path/to/chapters/');

    for (int i = 0; i < chapterTexts.length; i++) {
      final chapter = await chapterService.createChapter(
        artworkId: storyId,
        chapterNumber: i + 1,
        title: 'Chapter ${i + 1}: ${chapterTexts[i]['title']}',
        description: chapterTexts[i]['description'],
        content: chapterTexts[i]['content'],
        estimatedReadingTime: 15,
        wordCount: chapterTexts[i]['wordCount'],
        releaseDate: DateTime.now().add(
          Duration(days: 7 * i), // One week per chapter
        ),
        isPaid: true,
        price: 0.99,
        tags: ['episode', 'week_${i + 1}'],
      );
      chapterIds.add(chapter.id);
    }

    // Step 4: Generate release schedule
    await scheduleService.generateScheduleForSeries(
      artworkId: storyId,
      chapterIds: chapterIds,
      startDate: DateTime.now().add(Duration(days: 1)),
      schedule: ReleaseSchedule.weekly,
    );

    print('Weekly series uploaded with ${chapterIds.length} chapters scheduled');
  } catch (e) {
    print('Error uploading series: $e');
  }
}

Future<List<Map<String, dynamic>>> _loadAllChapters(String dirPath) async {
  final dir = Directory(dirPath);
  final chapters = <Map<String, dynamic>>[];
  
  for (final file in dir.listSync().whereType<File>()) {
    final content = await file.readAsString();
    chapters.add({
      'title': file.path.split('/').last.replaceAll('.txt', ''),
      'description': content.substring(0, 100),
      'content': content,
      'wordCount': content.split(' ').length,
    });
  }
  
  chapters.sort((a, b) => a['title'].compareTo(b['title']));
  return chapters;
}
```

---

## 3. Upload Comic (Webtoon-Style)

### Example: Upload Vertical Strip Comic

```dart
Future<void> uploadWebtoonComic() async {
  final artworkService = ArtworkService();
  final chapterService = ChapterService();
  
  try {
    // Step 1: Create comic artwork
    final comicId = await artworkService.uploadArtwork(
      imageFile: File('path/to/comic_cover.jpg'),
      title: 'Pixel Dreams',
      description: 'A webtoon about digital life',
      medium: 'Comic',
      styles: ['Webtoon', 'Comedy', 'Slice of Life'],
      tags: ['webtoon', 'comedy', 'digital'],
      price: 0.0, // Free for now
      isForSale: false,
    );

    // Step 2: Mark as comic content type
    final artwork = await artworkService.getArtworkById(comicId);
    final updatedArtwork = artwork?.copyWith(
      contentType: ArtworkContentType.comic,
      isSerializing: true,
      readingMetadata: {
        'readingDirection': 'vertical', // vertical for webtoons, ltr/rtl for traditional
        'panelsPerEpisode': 12,
        'language': 'en',
      },
      serializationConfig: {
        'releaseSchedule': 'weekly',
        'comicFormat': 'webtoon',
      },
    );

    if (updatedArtwork != null) {
      await artworkService.updateArtwork(updatedArtwork);
    }

    // Step 3: Load and organize comic panels
    final panelFiles = await _loadComicPanels('path/to/comic/panels/');

    // Create one "chapter" per episode (12 panels per chapter)
    int chapterNum = 1;
    for (int i = 0; i < panelFiles.length; i += 12) {
      final panelsForChapter = panelFiles.sublist(
        i,
        (i + 12).clamp(0, panelFiles.length),
      );

      // Upload panels to storage and get URLs
      final panelUrls = await Future.wait(
        panelsForChapter.map((file) => artworkService.uploadImageToStorage(file)),
      );

      // Create chapter with panel information
      await chapterService.createChapter(
        artworkId: comicId,
        chapterNumber: chapterNum,
        title: 'Episode $chapterNum',
        description: 'Episode $chapterNum of Pixel Dreams',
        content: '', // For comics, content might be minimal
        estimatedReadingTime: 5,
        wordCount: 0,
        releaseDate: DateTime.now().add(Duration(days: 7 * (chapterNum - 1))),
        panelImages: panelUrls,
        panelOrder: List.generate(panelUrls.length, (i) => i),
        thumbnailUrl: panelUrls.first,
        tags: ['episode_$chapterNum', 'webtoon'],
      );

      chapterNum++;
    }

    print('Webtoon uploaded with $chapterNum episodes');
  } catch (e) {
    print('Error uploading webtoon: $e');
  }
}

Future<List<File>> _loadComicPanels(String dirPath) async {
  final dir = Directory(dirPath);
  final panels = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
      .toList();
  panels.sort((a, b) => a.path.compareTo(b.path));
  return panels;
}
```

---

## 4. Upload Audio Content (Audiobook/Podcast)

### Example: Upload Audiobook Chapters

```dart
Future<void> uploadAudiobook() async {
  final artworkService = ArtworkService();
  final chapterService = ChapterService();
  
  try {
    // Step 1: Create audiobook entry
    final bookId = await artworkService.uploadArtwork(
      imageFile: File('path/to/audiobook_cover.jpg'),
      title: 'Echoes of Tomorrow',
      description: 'A science fiction audiobook narrated by acclaimed voice actors',
      medium: 'Audio',
      styles: ['Science Fiction', 'Audiobook'],
      tags: ['audiobook', 'scifi', 'narrated'],
      price: 9.99,
      isForSale: true,
    );

    // Step 2: Update with audio metadata
    final artwork = await artworkService.getArtworkById(bookId);
    final updatedArtwork = artwork?.copyWith(
      contentType: ArtworkContentType.audio,
      isSerializing: true,
      readingMetadata: {
        'totalDurationSeconds': 34200, // 9.5 hours
        'narratorName': 'Jane Smith',
        'language': 'en',
        'audioFormat': 'mp3',
      },
    );

    if (updatedArtwork != null) {
      await artworkService.updateArtwork(updatedArtwork);
    }

    // Step 3: Create chapters with audio files
    final audioFiles = await _loadAudioFiles('path/to/audiobook/chapters/');

    for (int i = 0; i < audioFiles.length; i++) {
      final audioUrl = await artworkService.uploadFileToStorage(
        audioFiles[i],
        'audiobooks/$bookId/chapter_${i + 1}',
      );

      await chapterService.createChapter(
        artworkId: bookId,
        chapterNumber: i + 1,
        title: 'Chapter ${i + 1}',
        description: 'Chapter ${i + 1} of Echoes of Tomorrow',
        content: audioUrl, // Store audio URL as content
        estimatedReadingTime: audioFiles[i].lengthSync() ~/ 1024 ~/ 128 ~/ 60, // Calculate from file size
        wordCount: 0, // N/A for audio
        releaseDate: DateTime.now(),
        audioUrls: [audioUrl],
        tags: ['chapter', 'audio'],
      );
    }

    print('Audiobook uploaded with ${audioFiles.length} chapters');
  } catch (e) {
    print('Error uploading audiobook: $e');
  }
}

Future<List<File>> _loadAudioFiles(String dirPath) async {
  final dir = Directory(dirPath);
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.mp3') || f.path.endsWith('.wav'))
      .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
}
```

---

## 5. Track Reading Progress

### Example: Implement Reading Session Analytics

```dart
class ReadingSessionController {
  final readingAnalyticsService = ReadingAnalyticsService();
  late ReadingAnalyticsModel currentSession;
  Timer? _progressTimer;

  Future<void> startReading(String artworkId, String? chapterId) async {
    currentSession = await readingAnalyticsService.startReadingSession(
      artworkId: artworkId,
      chapterId: chapterId,
    );

    // Track progress every 5 seconds
    _progressTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _updateProgress();
    });
  }

  void _updateProgress({
    required double scrollPosition, // 0.0 to 1.0
    required int elapsedSeconds,
  }) {
    readingAnalyticsService.updateReadingProgress(
      sessionId: currentSession.id,
      scrollPosition: scrollPosition,
      completionPercentage: scrollPosition * 100,
      elapsedSeconds: elapsedSeconds,
    );
  }

  Future<void> addBookmark(String chapterId, double position) async {
    await readingAnalyticsService.addBookmark(
      sessionId: currentSession.id,
      chapterId: chapterId,
      scrollPosition: position,
      note: 'Interesting passage',
    );
  }

  Future<void> finishReading() async {
    _progressTimer?.cancel();
    await readingAnalyticsService.completeReadingSession(
      sessionId: currentSession.id,
    );
  }

  Future<Map<String, dynamic>> getEngagementStats(String artworkId) async {
    return await readingAnalyticsService.getArtworkEngagementMetrics(artworkId);
  }
}
```

---

## 6. Query Written Content

### Example: Discovery Queries

```dart
class WrittenContentDiscovery {
  final artworkService = ArtworkService();
  final chapterService = ChapterService();

  // Find all written works
  Future<List<ArtworkModel>> getWrittenWorks() async {
    // Implementation depends on artwork_discovery_service
    // This is a conceptual example
    final artworks = await artworkService.getAllArtworks();
    return artworks
        .where((a) => a.contentType == ArtworkContentType.written)
        .toList();
  }

  // Get serialized stories
  Future<List<ArtworkModel>> getSerializedStories() async {
    final artworks = await artworkService.getAllArtworks();
    return artworks
        .where((a) =>
            a.contentType == ArtworkContentType.written && a.isSerializing)
        .toList();
  }

  // Get completed books
  Future<List<ArtworkModel>> getCompletedBooks() async {
    final artworks = await artworkService.getAllArtworks();
    return artworks
        .where((a) =>
            a.contentType == ArtworkContentType.written && !a.isSerializing)
        .toList();
  }

  // Find comics/webtoons
  Future<List<ArtworkModel>> getComics() async {
    final artworks = await artworkService.getAllArtworks();
    return artworks
        .where((a) => a.contentType == ArtworkContentType.comic)
        .toList();
  }

  // Get recently updated serials
  Future<List<ArtworkModel>> getRecentlyUpdatedSerials() async {
    final artworks = await artworkService.getAllArtworks();
    final serials = artworks
        .where((a) => a.contentType == ArtworkContentType.written && a.isSerializing)
        .toList();
    serials.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return serials.take(20).toList();
  }

  // Filter by reading time
  Future<List<ArtworkModel>> getShortStories() async {
    final artworks = await artworkService.getAllArtworks();
    return artworks
        .where((a) {
          final readingMetadata = a.readingMetadata;
          if (readingMetadata == null) return false;
          final time = readingMetadata['estimatedReadingTime'] as int?;
          return time != null && time < 60; // Less than 1 hour
        })
        .toList();
  }
}
```

---

## 7. UI Implementation Overview

### Text Reader Widget (Pseudo-code)

```dart
class TextReaderScreen extends StatefulWidget {
  final String artworkId;
  final String chapterId;

  const TextReaderScreen({
    required this.artworkId,
    required this.chapterId,
  });

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  final readingAnalyticsService = ReadingAnalyticsService();
  final chapterService = ChapterService();
  late ScrollController _scrollController;
  late String _sessionId;
  int _startTime = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeReadingSession();
  }

  Future<void> _initializeReadingSession() async {
    final session = await readingAnalyticsService.startReadingSession(
      artworkId: widget.artworkId,
      chapterId: widget.chapterId,
    );
    _sessionId = session.id;
    _startTime = DateTime.now().millisecondsSinceEpoch;

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final scrollPercentage = (currentScroll / maxScroll) * 100;
    final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - _startTime) ~/1000;

    readingAnalyticsService.updateReadingProgress(
      sessionId: _sessionId,
      scrollPosition: scrollPercentage / 100,
      completionPercentage: scrollPercentage,
      elapsedSeconds: elapsedSeconds,
    );
  }

  @override
  void dispose() {
    readingAnalyticsService.completeReadingSession(sessionId: _sessionId);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reading')),
      body: FutureBuilder<ChapterModel?>(
        future: chapterService.getChapterById(widget.artworkId, widget.chapterId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chapter = snapshot.data!;
          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    chapter.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Summary

The written content system provides:

1. **Multi-format support**: Books, stories, comics, audiobooks
2. **Serialization**: Weekly/monthly releases with scheduling
3. **Analytics**: Reading time, completion rates, engagement metrics
4. **Flexible pricing**: Per-chapter or full-work pricing
5. **Reader experience**: Bookmarks, progress tracking, resume reading

All models and services are production-ready and follow ArtBeat's architecture patterns.
