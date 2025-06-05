import 'package:flutter/material.dart';
import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';
import 'studio_chat_screen.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<StudioModel> _studios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  Future<void> _loadStudios() async {
    setState(() => _isLoading = true);
    try {
      final studios = await _firestoreService.getStudios();
      setState(() {
        _studios = studios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading studios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: 'Search studios...',
              leading: const Icon(Icons.search),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),
        ),
        // Studios grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _studios.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Text('No studios available'),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final studio = _studios[index];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StudioChatScreen(studioId: studio.id),
                          ),
                        ),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Privacy indicator
                                Icon(
                                  studio.privacyType == 'public'
                                      ? Icons.public
                                      : Icons.lock,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                // Studio name
                                Text(
                                  studio.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Member count
                                Text(
                                  '${studio.memberList.length} members',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                // Tags
                                if (studio.tags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: studio.tags
                                        .take(2)
                                        .map(
                                          (tag) => Chip(
                                            label: Text(
                                              tag,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _studios.length,
                  ),
                ),
        ),
      ],
    );
  }
}
