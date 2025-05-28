import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat/models/artist_profile_model.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:artbeat/models/gallery_invitation_model.dart';
import 'package:artbeat/models/commission_model.dart';
import 'package:artbeat/services/subscription_service.dart';
import 'package:artbeat/services/gallery_invitation_service.dart';
import 'package:artbeat/services/commission_service.dart';
import 'package:intl/intl.dart';

/// Screen for galleries to manage multiple artists
class GalleryArtistsManagementScreen extends StatefulWidget {
  const GalleryArtistsManagementScreen({super.key});

  @override
  State<GalleryArtistsManagementScreen> createState() =>
      _GalleryArtistsManagementScreenState();
}

class _GalleryArtistsManagementScreenState
    extends State<GalleryArtistsManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();
  final GalleryInvitationService _invitationService =
      GalleryInvitationService();

  bool _isLoading = true;
  bool _isPremiumGallery = false;
  String? _errorMessage;
  List<String> _galleryArtists = [];
  Map<String, ArtistProfileModel> _artistProfiles = {};
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingInvitations = [];
  bool _isLoadingInvitations = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGalleryData();
    _loadPendingInvitations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load gallery profile and associated artists
  Future<void> _loadGalleryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user has premium subscription
      final subscription = await _subscriptionService.getUserSubscription();
      final hasPremium = subscription != null &&
          subscription.tier == SubscriptionTier.premium &&
          subscription.isActive;

      if (!hasPremium) {
        setState(() {
          _isPremiumGallery = false;
          _isLoading = false;
          _errorMessage =
              'Gallery artist management requires a Gallery Plan subscription.';
        });
        return;
      }

      // Get gallery profile
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final galleryProfile =
          await _subscriptionService.getArtistProfileByUserId(userId);
      if (galleryProfile == null ||
          galleryProfile.userType != UserType.gallery) {
        setState(() {
          _errorMessage = 'No gallery profile found. Please create one first.';
          _isLoading = false;
        });
        return;
      }

      // Get associated artists
      final artistList = galleryProfile.galleryArtists ?? [];

      // Load artist profiles
      final artistProfiles = <String, ArtistProfileModel>{};
      for (String artistId in artistList) {
        final profile =
            await _subscriptionService.getArtistProfileById(artistId);
        if (profile != null) {
          artistProfiles[artistId] = profile;
        }
      }

      setState(() {
        _isPremiumGallery = true;
        _galleryArtists = artistList;
        _artistProfiles = artistProfiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading gallery data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Load pending invitations
  Future<void> _loadPendingInvitations() async {
    setState(() {
      _isLoadingInvitations = true;
    });

    try {
      final sentInvitations = await _invitationService.getSentInvitations();

      setState(() {
        _pendingInvitations = sentInvitations
            .where(
                (invitation) => invitation.status == InvitationStatus.pending)
            .map((invitation) => {
                  'id': invitation.id,
                  'artistName': invitation.artistName,
                  'artistId': invitation.artistId,
                  'artistImageUrl': invitation.artistImageUrl,
                  'createdAt': invitation.createdAt,
                })
            .toList();
        _isLoadingInvitations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInvitations = false;
      });
      print('Error loading invitations: $e');
    }
  }

  /// Add artist to gallery
  Future<void> _addArtistToGallery(String artistProfileId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get gallery profile
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final galleryProfile =
          await _subscriptionService.getArtistProfileByUserId(userId);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Add artist to gallery's list
      List<String> updatedArtists = [..._galleryArtists];
      if (!updatedArtists.contains(artistProfileId)) {
        updatedArtists.add(artistProfileId);
      }

      // Update gallery profile
      await _subscriptionService.saveArtistProfile(
        displayName: galleryProfile.displayName,
        bio: galleryProfile.bio,
        mediums: galleryProfile.mediums,
        styles: galleryProfile.styles,
        location: galleryProfile.location,
        websiteUrl: galleryProfile.websiteUrl,
        etsy: galleryProfile.etsy,
        instagram: galleryProfile.instagram,
        facebook: galleryProfile.facebook,
        twitter: galleryProfile.twitter,
        userType: UserType.gallery,
        profileId: galleryProfile.id,
        galleryArtists: updatedArtists,
      );

      // Reload gallery data
      await _loadGalleryData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist added to gallery successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding artist: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Remove artist from gallery
  Future<void> _removeArtistFromGallery(String artistProfileId) async {
    // Confirm removal
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Artist'),
        content: const Text(
            'Are you sure you want to remove this artist from your gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldRemove != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get gallery profile
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final galleryProfile =
          await _subscriptionService.getArtistProfileByUserId(userId);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Remove artist from gallery's list
      List<String> updatedArtists =
          _galleryArtists.where((id) => id != artistProfileId).toList();

      // Update gallery profile
      await _subscriptionService.saveArtistProfile(
        displayName: galleryProfile.displayName,
        bio: galleryProfile.bio,
        mediums: galleryProfile.mediums,
        styles: galleryProfile.styles,
        location: galleryProfile.location,
        websiteUrl: galleryProfile.websiteUrl,
        etsy: galleryProfile.etsy,
        instagram: galleryProfile.instagram,
        facebook: galleryProfile.facebook,
        twitter: galleryProfile.twitter,
        userType: UserType.gallery,
        profileId: galleryProfile.id,
        galleryArtists: updatedArtists,
      );

      // Reload gallery data
      await _loadGalleryData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artist removed from gallery')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error removing artist: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Search for artists to add to gallery
  Future<void> _searchAndAddArtist() async {
    // Show search dialog
    await showDialog(
      context: context,
      builder: (context) => _ArtistSearchDialog(
        onArtistSelected: _addArtistToGallery,
        currentArtists: _galleryArtists,
      ),
    );
  }

  /// Send bulk invitations to artists
  Future<void> _sendBulkInvitations(
      List<String> artistIds, String message) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _invitationService.sendBulkInvitations(
        artistProfileIds: artistIds,
        message: message,
      );

      // Reload invitations
      await _loadPendingInvitations();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Invitations sent to ${artistIds.length} artists')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error sending invitations: ${e.toString()}';
      });
    }
  }

  /// Cancel an invitation
  Future<void> _cancelInvitation(String invitationId) async {
    try {
      await _invitationService.cancelInvitation(invitationId);
      await _loadPendingInvitations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  /// Show dialog for bulk inviting artists
  Future<void> _showBulkInviteDialog() async {
    final TextEditingController messageController = TextEditingController(
      text:
          "I'd like to invite you to join my gallery. As an artist in our gallery, you'll have the opportunity to showcase your work to our audience and benefit from our marketing efforts.",
    );
    List<String> selectedArtistIds = [];
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Bulk Invite Artists'),
            content: SizedBox(
              width: 500,
              height: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Artists',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    onChanged: (value) async {
                      if (value.length < 3) {
                        setState(() {
                          searchResults = [];
                        });
                        return;
                      }

                      setState(() {
                        isSearching = true;
                      });

                      try {
                        final results =
                            await _subscriptionService.searchArtists(
                          query: value,
                          limit: 20,
                        );

                        // Filter out artists already in gallery or already selected
                        final filteredResults = results
                            .where((artist) =>
                                !_galleryArtists.contains(artist.id) &&
                                !selectedArtistIds.contains(artist.id))
                            .toList();

                        setState(() {
                          searchResults = filteredResults
                              .map((artist) => {
                                    'id': artist.id,
                                    'name': artist.displayName,
                                    'imageUrl': artist.profileImageUrl,
                                    'location': artist.location,
                                  })
                              .toList();
                          isSearching = false;
                        });
                      } catch (e) {
                        setState(() {
                          searchResults = [];
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (searchResults.isNotEmpty) ...[
                          const Text(
                            'Search Results:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            flex: 1,
                            child: ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final artist = searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: artist['imageUrl'] != null
                                        ? NetworkImage(artist['imageUrl']!)
                                        : null,
                                    child: artist['imageUrl'] == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(artist['name']),
                                  subtitle: Text(
                                    artist['location'] ?? 'No location',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle),
                                    onPressed: () {
                                      setState(() {
                                        selectedArtistIds.add(artist['id']);
                                        searchResults.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Selected Artists:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 1,
                          child: selectedArtistIds.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No artists selected',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: selectedArtistIds.length,
                                  itemBuilder: (context, index) {
                                    final artistId = selectedArtistIds[index];
                                    return FutureBuilder<dynamic>(
                                      future: _subscriptionService
                                          .getArtistProfileById(artistId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            !snapshot.hasData) {
                                          return const ListTile(
                                            leading: CircleAvatar(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                            title: Text('Loading...'),
                                          );
                                        }

                                        final artist = snapshot.data;
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage:
                                                artist.profileImageUrl != null
                                                    ? NetworkImage(
                                                        artist.profileImageUrl)
                                                    : null,
                                            child:
                                                artist.profileImageUrl == null
                                                    ? const Icon(Icons.person)
                                                    : null,
                                          ),
                                          title: Text(artist.displayName),
                                          subtitle: Text(
                                            artist.location ?? 'No location',
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                selectedArtistIds
                                                    .removeAt(index);
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Invitation Message:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Enter your invitation message',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedArtistIds.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _sendBulkInvitations(
                          selectedArtistIds,
                          messageController.text,
                        );
                      },
                child: Text('Send ${selectedArtistIds.length} Invitations'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show dialog to manage commission for an artist
  Future<void> _showCommissionDialog(String artistProfileId) async {
    final artistProfile = _artistProfiles[artistProfileId];
    if (artistProfile == null) return;

    final commissionService = CommissionService();

    // Get existing commission if any
    bool isLoading = true;
    double commissionRate = 30.0; // Default commission rate
    String status = 'none';
    String commissionId = '';

    try {
      final commissions = await commissionService.getGalleryCommissions();
      final existingCommission = commissions.firstWhere(
        (commission) => commission.artistId == artistProfileId,
        orElse: () => CommissionModel(
          id: '',
          galleryId: '',
          galleryUserId: '',
          artistId: '',
          artistUserId: '',
          commissionRate: 0,
          status: CommissionStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      if (existingCommission.id.isNotEmpty) {
        commissionRate = existingCommission.commissionRate;
        status = existingCommission.status.name;
        commissionId = existingCommission.id;
      }

      isLoading = false;
    } catch (e) {
      isLoading = false;
    }

    // Show dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Commission rate slider
          final commissionRateController = TextEditingController(
            text: commissionRate.toString(),
          );

          return AlertDialog(
            title: Text('Commission: ${artistProfile.displayName}'),
            content: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (status != 'none') ...[
                          Text(
                            'Current Status: ${status.toUpperCase()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'active'
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Commission Rate (%):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: commissionRate,
                                min: 0,
                                max: 100,
                                divisions: 20,
                                label: commissionRate.round().toString(),
                                onChanged: (value) {
                                  setState(() {
                                    commissionRate = value;
                                    commissionRateController.text =
                                        value.toString();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: TextField(
                                controller: commissionRateController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  suffix: Text('%'),
                                ),
                                onChanged: (value) {
                                  final newValue = double.tryParse(value);
                                  if (newValue != null &&
                                      newValue >= 0 &&
                                      newValue <= 100) {
                                    setState(() {
                                      commissionRate = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Commission Terms:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const TextField(
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Enter additional commission terms...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              if (status != 'none')
                TextButton(
                  onPressed: () async {
                    try {
                      await commissionService.updateCommissionStatus(
                        commissionId: commissionId,
                        status: CommissionStatus.cancelled,
                      );
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Commission agreement cancelled')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Cancel Agreement',
                      style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (status == 'none') {
                      // Create new commission
                      await commissionService.createCommission(
                        galleryId: artistProfile.id,
                        artistId: artistProfileId,
                        commissionRate: commissionRate,
                        terms: {
                          'defaultTerms':
                              'Standard gallery commission agreement',
                        },
                      );
                    } else {
                      // Update existing commission
                      await commissionService.updateCommissionTerms(
                        commissionId: commissionId,
                        terms: {
                          'commissionRate': commissionRate,
                          'updatedAt': DateTime.now(),
                        },
                      );
                    }
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Commission agreement saved')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: Text(
                    status == 'none' ? 'Create Agreement' : 'Update Agreement'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery Artists')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show upgrade prompt for non-premium users
    if (!_isPremiumGallery) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gallery Artists')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gallery Artist Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ??
                      'This feature is available with the Gallery Plan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Upgrade to Gallery Plan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Artists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Artist',
            onPressed: _searchAndAddArtist,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Bulk Invite',
            onPressed: _showBulkInviteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics Dashboard',
            onPressed: () =>
                Navigator.pushNamed(context, '/artist/gallery-analytics'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'Artists',
            ),
            Tab(
              icon: Icon(Icons.mail),
              text: 'Invitations',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Artists tab
          RefreshIndicator(
            onRefresh: _loadGalleryData,
            child: _galleryArtists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_add,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No artists yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add artists to your gallery to manage them',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _searchAndAddArtist,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Artist'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _galleryArtists.length,
                    itemBuilder: (context, index) {
                      final artistId = _galleryArtists[index];
                      final artistProfile = _artistProfiles[artistId];

                      if (artistProfile == null) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundImage: artistProfile.profileImageUrl !=
                                    null
                                ? NetworkImage(artistProfile.profileImageUrl!)
                                : null,
                            child: artistProfile.profileImageUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            artistProfile.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                artistProfile.location ?? 'No location',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Mediums: ${artistProfile.mediums.join(", ")}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.monetization_on),
                                tooltip: 'Manage Commission',
                                onPressed: () =>
                                    _showCommissionDialog(artistId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                tooltip: 'Remove Artist',
                                onPressed: () =>
                                    _removeArtistFromGallery(artistId),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/artist/profile/view',
                              arguments: {'artistProfileId': artistId},
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Invitations tab
          RefreshIndicator(
            onRefresh: _loadPendingInvitations,
            child: _isLoadingInvitations
                ? const Center(child: CircularProgressIndicator())
                : _pendingInvitations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.mail,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No pending invitations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Invite artists to join your gallery',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showBulkInviteDialog,
                              icon: const Icon(Icons.group_add),
                              label: const Text('Bulk Invite'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingInvitations.length,
                        itemBuilder: (context, index) {
                          final invitation = _pendingInvitations[index];
                          final createdAt = invitation['createdAt'] as DateTime;
                          final formattedDate =
                              DateFormat('MMM d, yyyy').format(createdAt);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundImage:
                                    invitation['artistImageUrl'] != null
                                        ? NetworkImage(
                                            invitation['artistImageUrl']!)
                                        : null,
                                child: invitation['artistImageUrl'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                invitation['artistName'] ?? 'Unknown Artist',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sent on $formattedDate',
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Status: Pending'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.cancel,
                                    color: Colors.orange),
                                tooltip: 'Cancel Invitation',
                                onPressed: () =>
                                    _cancelInvitation(invitation['id']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for searching and selecting artists to add to gallery
class _ArtistSearchDialog extends StatefulWidget {
  final Function(String artistProfileId) onArtistSelected;
  final List<String> currentArtists;

  const _ArtistSearchDialog({
    required this.onArtistSelected,
    required this.currentArtists,
  });

  @override
  State<_ArtistSearchDialog> createState() => _ArtistSearchDialogState();
}

class _ArtistSearchDialogState extends State<_ArtistSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<ArtistProfileModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search for artists
  Future<void> _searchArtists(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _subscriptionService.searchArtists(
        query: query,
        limit: 20,
      );

      setState(() {
        // Filter out artists already in the gallery
        _searchResults = results
            .where((artist) => !widget.currentArtists.contains(artist.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Find Artists',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchArtists,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Type to search for artists'
                                : 'No artists found',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final artist = _searchResults[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: artist.profileImageUrl != null
                                    ? NetworkImage(artist.profileImageUrl!)
                                    : null,
                                child: artist.profileImageUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(artist.displayName),
                              subtitle: Text(
                                artist.location ?? 'No location',
                              ),
                              onTap: () {
                                widget.onArtistSelected(artist.id);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
