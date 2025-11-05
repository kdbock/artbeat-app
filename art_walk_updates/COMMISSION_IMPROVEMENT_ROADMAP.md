# Commission System - Quick Implementation Guide

## Phase 1: Quick Wins (Can be done in 1 sprint)

These changes require minimal effort but significantly improve discoverability and engagement.

---

## Win #1: Add Commission Status Badge to Artist Profile

**File:** `/packages/artbeat_artist/lib/src/screens/artist_profile_screen.dart`
**Time:** ~45 minutes

### Changes Needed:

1. **Update ArtistProfileModel to include commission fields**

   ```dart
   // In artbeat_artist package - artist profile model
   final bool? acceptingCommissions;
   final List<CommissionType>? commissionTypes;
   final double? commissionBasePrice;
   final int? averageTurnaroundDays;
   ```

2. **Add commission badge to profile header**

   ```dart
   // Display in profile header
   if (artist.acceptingCommissions == true)
     Chip(
       icon: const Icon(Icons.handshake),
       label: const Text('Accepting Commissions'),
       backgroundColor: Colors.green.shade100,
     )
   ```

3. **Add commission info section**
   ```dart
   if (artist.acceptingCommissions == true)
     Card(
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Commissions Available',
               style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 8),
             Text('Types: ${artist.commissionTypes?.map((t) => t.displayName).join(", ") ?? "Various"}'),
             Text('Starting at: \$${artist.commissionBasePrice?.toStringAsFixed(0)}'),
             Text('Turnaround: ${artist.averageTurnaroundDays} days'),
             const SizedBox(height: 12),
             ElevatedButton.icon(
               onPressed: _requestCommission,
               icon: const Icon(Icons.add),
               label: const Text('Request Commission'),
             ),
           ],
         ),
       ),
     )
   ```

### Database Schema Update:

```firestore
collection: artistProfiles
  doc: {artistId}
    fields:
      - acceptingCommissions: boolean
      - commissionTypes: array<string>
      - commissionBasePrice: number
      - averageTurnaroundDays: number
```

### Testing:

- [ ] Display badge when artist has commissions enabled
- [ ] Hide section when commissions disabled
- [ ] "Request Commission" button navigation works
- [ ] Info displays correctly for multiple commission types

---

## Win #2: Add "Browse Commission Artists" to Community Hub

**File:** `/packages/artbeat_community/lib/screens/community_hub_screen.dart`
**Time:** ~30 minutes

### Changes Needed:

1. **Add section card to community hub**

   ```dart
   Card(
     child: InkWell(
       onTap: _browseCommissionArtists,
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 const Icon(Icons.handshake, size: 24),
                 const SizedBox(width: 12),
                 Text('Commission Talented Artists',
                   style: Theme.of(context).textTheme.titleLarge),
               ],
             ),
             const SizedBox(height: 8),
             Text('Find artists accepting custom commissions',
               style: Theme.of(context).textTheme.bodyMedium),
             const SizedBox(height: 12),
             Row(
               children: [
                 const Spacer(),
                 TextButton.icon(
                   onPressed: _browseCommissionArtists,
                   icon: const Icon(Icons.arrow_forward),
                   label: const Text('Browse'),
                 ),
               ],
             ),
           ],
         ),
       ),
     ),
   )
   ```

2. **Add navigation method**

   ```dart
   void _browseCommissionArtists() {
     Navigator.of(context).push(
       MaterialPageRoute(
         builder: (context) => const ArtistSelectionScreen(
           filterByCommissions: true,
         ),
       ),
     );
   }
   ```

3. **Update ArtistSelectionScreen to support filtering**

   ```dart
   class ArtistSelectionScreen extends StatefulWidget {
     final bool filterByCommissions;

     const ArtistSelectionScreen({
       super.key,
       this.filterByCommissions = false,
     });
   }

   // In _loadArtists()
   Future<void> _loadArtists() async {
     setState(() => _isLoading = true);
     try {
       List<core.ArtistProfileModel> artists;

       if (widget.filterByCommissions) {
         artists = await _artistService.getCommissionArtists();
       } else {
         artists = await _artistService.getFeaturedArtistProfiles();
       }

       setState(() {
         _artists = artists;
         _filteredArtists = artists;
         _isLoading = false;
       });
     } catch (e) {
       // error handling
     }
   }
   ```

4. **Add method to ArtistService**
   ```dart
   // In artbeat_core/lib/src/services/artist_service.dart
   Future<List<ArtistProfileModel>> getCommissionArtists() async {
     try {
       final query = await FirebaseFirestore.instance
           .collection('artistProfiles')
           .where('acceptingCommissions', isEqualTo: true)
           .orderBy('commissionBasePrice', descending: false)
           .limit(50)
           .get();

       return query.docs
           .map((doc) => ArtistProfileModel.fromFirestore(doc))
           .toList();
     } catch (e) {
       throw Exception('Failed to load commission artists: $e');
     }
   }
   ```

### Testing:

- [ ] Card appears in community hub
- [ ] Click navigates to filtered artist list
- [ ] Only artists with acceptingCommissions=true appear
- [ ] Filter works in search

---

## Win #3: Add Commission Stats to Drawer

**File:** `/packages/artbeat_core/lib/src/widgets/artbeat_drawer_items.dart`
**Time:** ~20 minutes

### Changes Needed:

1. **Create commission stats widget**

   ```dart
   class CommissionStatsItem extends StatelessWidget {
     final int activeCount;
     final int completedCount;
     final double earnings;

     const CommissionStatsItem({
       required this.activeCount,
       required this.completedCount,
       required this.earnings,
     });

     @override
     Widget build(BuildContext context) {
       return Container(
         padding: const EdgeInsets.all(12),
         decoration: BoxDecoration(
           color: Colors.blue.shade50,
           borderRadius: BorderRadius.circular(8),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               'Commission Stats',
               style: Theme.of(context).textTheme.titleSmall,
             ),
             const SizedBox(height: 8),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   children: [
                     Text(activeCount.toString(),
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                       )),
                     const Text('Active', style: TextStyle(fontSize: 12)),
                   ],
                 ),
                 Column(
                   children: [
                     Text(completedCount.toString(),
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                       )),
                     const Text('Completed', style: TextStyle(fontSize: 12)),
                   ],
                 ),
                 Column(
                   children: [
                     Text('\$${earnings.toStringAsFixed(0)}',
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                       )),
                     const Text('Earned', style: TextStyle(fontSize: 12)),
                   ],
                 ),
               ],
             ),
           ],
         ),
       );
     }
   }
   ```

2. **Add to drawer header**
   ```dart
   // In ArtbeatDrawer widget, after profile section
   if (userRoles.contains('artist'))
     FutureBuilder<CommissionStats>(
       future: _loadCommissionStats(),
       builder: (context, snapshot) {
         if (snapshot.hasData) {
           return CommissionStatsItem(
             activeCount: snapshot.data!.active,
             completedCount: snapshot.data!.completed,
             earnings: snapshot.data!.earnings,
           );
         }
         return const SizedBox.shrink();
       },
     )
   ```

### Testing:

- [ ] Stats display for artist users only
- [ ] Numbers update correctly
- [ ] Click navigates to commission hub

---

## Win #4: Add Commission Filter to Artist Search

**File:** `/packages/artbeat_community/lib/screens/commissions/artist_selection_screen.dart`
**Time:** ~30 minutes

### Changes Needed:

1. **Add commission filter chip**

   ```dart
   // In _buildSearchArea()
   Column(
     children: [
       // Existing search bar
       TextField(...),
       const SizedBox(height: 12),
       // Add filter chips
       SingleChildScrollView(
         scrollDirection: Axis.horizontal,
         child: Row(
           children: [
             FilterChip(
               label: const Text('Accepting Commissions'),
               selected: _showOnlyCommissionArtists,
               onSelected: (selected) {
                 setState(() => _showOnlyCommissionArtists = selected);
                 _filterArtists();
               },
             ),
             const SizedBox(width: 8),
             FilterChip(
               label: const Text('Digital'),
               selected: _selectedCommissionType == 'digital',
               onSelected: (selected) {
                 setState(() => _selectedCommissionType =
                   selected ? 'digital' : null);
                 _filterArtists();
               },
             ),
             const SizedBox(width: 8),
             FilterChip(
               label: const Text('Physical'),
               selected: _selectedCommissionType == 'physical',
               onSelected: (selected) {
                 setState(() => _selectedCommissionType =
                   selected ? 'physical' : null);
                 _filterArtists();
               },
             ),
           ],
         ),
       ),
     ],
   )
   ```

2. **Update filter logic**
   ```dart
   void _filterArtists() {
     setState(() {
       _filteredArtists = _artists.where((artist) {
         // Filter by commission status
         if (_showOnlyCommissionArtists) {
           if (artist.acceptingCommissions != true) return false;
         }

         // Filter by commission type
         if (_selectedCommissionType != null) {
           final types = artist.commissionTypes ?? [];
           if (!types.contains(_selectedCommissionType)) return false;
         }

         // Filter by search query
         if (_searchQuery.isNotEmpty) {
           return artist.displayName
               .toLowerCase()
               .contains(_searchQuery.toLowerCase());
         }

         return true;
       }).toList();
     });
   }
   ```

### Testing:

- [ ] Filter chips display
- [ ] Clicking chip filters results
- [ ] Multiple filters work together
- [ ] Search works with filters

---

## Win #5: Show Commission Count in Artist Cards

**File:** Update artist card component `artbeat_core/lib/src/widgets/artist_card.dart`
**Time:** ~20 minutes

### Changes Needed:

```dart
// Add to existing ArtistCard widget

if (artist.acceptingCommissions == true)
  Positioned(
    top: 8,
    right: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Commissions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),

// Also add commission info to bottom of card
if (artist.acceptingCommissions == true)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      'From \$${artist.commissionBasePrice?.toStringAsFixed(0)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.green,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
```

### Testing:

- [ ] Badge appears on commission artists
- [ ] Price displays correctly
- [ ] No badge on non-commission artists
- [ ] Layout doesn't break on different screen sizes

---

## Integration Checklist

Use this to track implementation:

### Database/Firestore Updates

- [ ] Add commission fields to artistProfiles collection
- [ ] Migrate existing artist data (set defaults)
- [ ] Create indexes for commission queries

### Code Changes

- [ ] Update ArtistProfileModel with commission fields
- [ ] Update artist profile screen UI
- [ ] Add getCommissionArtists() to ArtistService
- [ ] Update ArtistSelectionScreen filtering
- [ ] Add CommissionStatsItem widget
- [ ] Update drawer to show stats
- [ ] Update artist card UI
- [ ] Add filter chips to search

### UI/UX

- [ ] Review all new screens at different sizes
- [ ] Ensure touch targets are large enough (48dp minimum)
- [ ] Check color contrast for accessibility
- [ ] Test on dark mode

### Testing

- [ ] Unit tests for filtering logic
- [ ] Widget tests for new components
- [ ] Integration test for commission flow
- [ ] Manual test on iOS and Android

### Deployment

- [ ] Create feature branch
- [ ] Code review
- [ ] Merge to main
- [ ] Tag release
- [ ] Update app store listings with new feature

---

## Timeline Estimate

| Task                            | Time         | Priority |
| ------------------------------- | ------------ | -------- |
| Add commission badge to profile | 45 min       | P0       |
| Add browse commissions to hub   | 30 min       | P0       |
| Add stats to drawer             | 20 min       | P1       |
| Add search filters              | 30 min       | P1       |
| Update artist cards             | 20 min       | P1       |
| Testing & QA                    | 2-3 hours    | P0       |
| **Total**                       | **~5 hours** | -        |

**Can be completed in 1 day** with focused effort.

---

## Rollout Strategy

1. **Internal Testing** (1-2 days)

   - Developers test all flows
   - QA verifies on multiple devices

2. **Beta Release** (3-5 days)

   - Release to 10-20% of users
   - Monitor crash logs and analytics
   - Gather feedback

3. **Full Release** (1 day)

   - Roll out to all users
   - Monitor engagement metrics
   - Be ready for support questions

4. **Post-Launch** (ongoing)
   - Track adoption metrics
   - Gather user feedback
   - Plan Phase 2 enhancements

---

## Success Metrics to Track

After launch, monitor:

1. **Adoption**

   - % of artists with commissions enabled
   - Commission artists as % of total artists
   - Browse commission artists page views

2. **Engagement**

   - Commission request creation rate
   - Quote acceptance rate
   - Average commission value

3. **User Satisfaction**

   - Commission feature rating
   - Support tickets about commissions
   - Feature request votes

4. **Revenue**
   - Total commission transaction value
   - Revenue by commission type
   - Average commission price

---

## Follow-Up Phases

After Phase 1 Quick Wins, prioritize based on metrics:

**Phase 2: Onboarding (if adoption is low)**

- Commission setup wizard
- In-app prompts and tooltips
- Commission FAQ section

**Phase 3: Client Experience (if engagement is low)**

- Commission request templates
- Progress tracking UI
- Payment milestone management

**Phase 4: Advanced (if everything is working)**

- Commission booking calendar
- Ratings and reviews
- Gallery/showcase features

---

## Questions to Ask Before Starting

1. Do we have Firestore indexes set up for commission queries?
2. Should commission artists appear in regular artist searches?
3. What's the minimum price tier for commissions?
4. Should we enable commissions for all artists or specific tiers?
5. Do we need approval workflow for commission settings?
6. What's our target adoption rate?

---

## Common Pitfalls to Avoid

❌ **Don't:**

- Make commission settings too complex
- Hide commissions deep in menus
- Show commissions to users who can't act on them
- Ignore commission messages
- Create duplicate commission functionality

✅ **Do:**

- Make commission discovery obvious
- Show commission status prominently
- Provide clear calls-to-action
- Integrate messaging properly
- Keep UI consistent with rest of app

---

## Support & Documentation

Create these docs before launch:

1. **For Artists:** "How to Accept Commissions"
2. **For Clients:** "How to Request a Commission"
3. **FAQ:** Common commission questions
4. **Troubleshooting:** Common issues and fixes

---

**Status:** Ready for implementation
**Last Updated:** 2025
**Owner:** ArtBeat Team
