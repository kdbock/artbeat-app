import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

/// Capture Search Screen
class CaptureSearchScreen extends StatefulWidget {
  const CaptureSearchScreen({Key? key}) : super(key: key);

  @override
  State<CaptureSearchScreen> createState() => _CaptureSearchScreenState();
}

class _CaptureSearchScreenState extends State<CaptureSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CaptureService _captureService = CaptureService();
  List<CaptureModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      // Simple search by title, location, or tags
      final allCaptures = await _captureService.getAllCaptures(limit: 50);
      _results = allCaptures.where((capture) {
        final title = (capture.title ?? '').toLowerCase();
        final location = (capture.locationName ?? '').toLowerCase();
        final tags = (capture.tags ?? []).map((t) => t.toString().toLowerCase()).join(' ');
        return title.contains(query) || location.contains(query) || tags.contains(query);
      }).toList();
    } catch (e) {
      _results = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Captures'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, location, or tags',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            if (_hasSearched && !_isLoading)
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text('No captures found.'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final capture = _results[index];
                          return Card(
                            child: ListTile(
                              leading: SizedBox(
                                width: 48,
                                height: 48,
                                child: SecureNetworkImage(
                                  imageUrl: capture.imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                              title: Text(capture.title ?? 'Untitled'),
                              subtitle: Text(capture.locationName ?? ''),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/capture/detail',
                                  arguments: {'captureId': capture.id},
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
