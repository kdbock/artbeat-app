import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';
import '../models/event_model.dart';

/// Widget for displaying upcoming local events in a horizontal scrollable row
class UpcomingEventsRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const UpcomingEventsRowWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get current date for filtering
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('isPublic', isEqualTo: true)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
                .orderBy('date')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No upcoming events in your area'),
                  ),
                );
              }

              final events = snapshot.data!.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .where((event) {
                // Filter to only show events with locations containing the zipCode
                return event.location.contains(zipCode);
              }).toList();

              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No upcoming events in your area'),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final formattedDate = DateFormat.MMMd().format(event.date);
                  final formattedTime = DateFormat.jm().format(
                    DateTime(
                      event.date.year,
                      event.date.month,
                      event.date.day,
                      event.startTime.hour,
                      event.startTime.minute,
                    ),
                  );

                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, '/calendar/event-detail',
                        arguments: {'eventId': event.id}),
                    child: Container(
                      width: 240,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12.0)),
                              child: Image.network(
                                event.imageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.event, size: 40),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$formattedDate at $formattedTime',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          event.location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
          ),
        ),
      ],
    );
  }
}
