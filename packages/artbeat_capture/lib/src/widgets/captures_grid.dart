import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;

class CapturesGrid extends StatefulWidget {
  final String userId;
  final bool showPublicOnly;
  final void Function(CaptureModel capture)? onCaptureTap;

  const CapturesGrid({
    super.key,
    required this.userId,
    this.showPublicOnly = false,
    this.onCaptureTap,
  });

  @override
  State<CapturesGrid> createState() => _CapturesGridState();
}

class _CapturesGridState extends State<CapturesGrid> {
  late Stream<QuerySnapshot<CaptureModel>> _capturesStream;

  @override
  void initState() {
    super.initState();
    _setupCapturesStream();
  }

  void _setupCapturesStream() {
    var query = FirebaseFirestore.instance
        .collection('captures')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .withConverter<CaptureModel>(
          fromFirestore: (snapshot, _) =>
              CaptureModel.fromFirestore(snapshot, null),
          toFirestore: (capture, _) => capture.toFirestore(),
        );

    if (widget.showPublicOnly) {
      query = query.where('isPublic', isEqualTo: true);
    }

    _capturesStream = query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<CaptureModel>>(
      stream: _capturesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading captures: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading captures',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final captures = snapshot.data?.docs.map((doc) => doc.data()).toList();

        if (captures == null || captures.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No captures yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: captures.length,
          itemBuilder: (context, index) {
            final capture = captures[index];
            return InkWell(
              onTap: () => widget.onCaptureTap?.call(capture),
              child: Hero(
                tag: 'capture_${capture.id}',
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    image: DecorationImage(
                      image: NetworkImage(
                        capture.thumbnailUrl ?? capture.imageUrl,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (!capture.isPublic)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      if (capture.location != null)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
