import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../tools/migrate_storage_to_firestore.dart' as migration;

/// Debug-only migration button for artwork migration
class MigrateArtButton extends StatelessWidget {
  const MigrateArtButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      icon: const Icon(Icons.cloud_upload),
      label: const Text('Migrate Art'),
      onPressed: () async {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Starting migration...')));
        try {
          await migration.migrateArtworkStorageToFirestore();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Migration complete!')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Migration failed: $e')));
        }
      },
    );
  }
}
