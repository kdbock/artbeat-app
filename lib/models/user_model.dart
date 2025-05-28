import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username, email, phoneNumber, authProvider;
  final bool isVerified;
  final String fullName, bio, profileImageUrl, coverImageUrl;
  final String gender;
  final DateTime? birthDate;
  final String location, website;
  final bool isOnline;
  final Timestamp lastSeen, createdAt, updatedAt;
  final String status;
  final List<String> followers, following, blockedUsers;
  final List<String> friendRequestsSent, friendRequestsReceived;
  final String allowMessagesFrom;
  final List<String> chatMutedUsers;
  final bool notificationsEnabled, emailNotifications;
  final String themePreference, language;
  final Map<String, dynamic> privacySettings, contentFilters;
  final List<String> posts,
      likedPosts,
      savedPosts,
      comments,
      sharedPosts,
      favoriteUsers;
  final bool isBanned;
  final String banReason;
  final List<String> reportedBy;
  final int reportCount;
  final String subscriptionStatus;
  final Timestamp? subscriptionExpiry;
  final Map<String, dynamic>? payoutInfo;
  final List<Map<String, dynamic>> donationsReceived;
  final double adRevenue;
  final bool isFollowedByCurrentUser;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.authProvider,
    required this.isVerified,
    required this.fullName,
    required this.bio,
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.gender,
    this.birthDate,
    required this.location,
    required this.website,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.followers,
    required this.following,
    required this.blockedUsers,
    required this.friendRequestsSent,
    required this.friendRequestsReceived,
    required this.allowMessagesFrom,
    required this.chatMutedUsers,
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.themePreference,
    required this.language,
    required this.privacySettings,
    required this.contentFilters,
    required this.posts,
    required this.likedPosts,
    required this.savedPosts,
    required this.comments,
    required this.sharedPosts,
    required this.favoriteUsers,
    required this.isBanned,
    required this.banReason,
    required this.reportedBy,
    required this.reportCount,
    required this.subscriptionStatus,
    this.subscriptionExpiry,
    this.payoutInfo,
    required this.donationsReceived,
    required this.adRevenue,
    this.isFollowedByCurrentUser = false,
  });

  // Factory constructor to create a UserModel from Firestore data
  factory UserModel.fromFirebase(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      authProvider: data['authProvider'] ?? 'email',
      isVerified: data['isVerified'] ?? false,
      fullName: data['fullName'] ?? '',
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      gender: data['gender'] ?? '',
      birthDate:
          data['birthDate'] != null
              ? (data['birthDate'] as Timestamp).toDate()
              : null,
      location: data['location'] ?? '',
      website: data['website'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      status: data['status'] ?? '',
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      friendRequestsSent: List<String>.from(data['friendRequestsSent'] ?? []),
      friendRequestsReceived: List<String>.from(
        data['friendRequestsReceived'] ?? [],
      ),
      allowMessagesFrom: data['allowMessagesFrom'] ?? 'everyone',
      chatMutedUsers: List<String>.from(data['chatMutedUsers'] ?? []),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      emailNotifications: data['emailNotifications'] ?? false,
      themePreference: data['themePreference'] ?? 'system',
      language: data['language'] ?? 'en',
      privacySettings:
          data['privacySettings'] ??
          {'showEmail': false, 'showBirthDate': false},
      contentFilters: data['contentFilters'] ?? {'matureContent': false},
      posts: List<String>.from(data['posts'] ?? []),
      likedPosts: List<String>.from(data['likedPosts'] ?? []),
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
      comments: List<String>.from(data['comments'] ?? []),
      sharedPosts: List<String>.from(data['sharedPosts'] ?? []),
      favoriteUsers: List<String>.from(data['favoriteUsers'] ?? []),
      isBanned: data['isBanned'] ?? false,
      banReason: data['banReason'] ?? '',
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      reportCount: data['reportCount'] ?? 0,
      subscriptionStatus: data['subscriptionStatus'] ?? 'free',
      subscriptionExpiry: data['subscriptionExpiry'],
      payoutInfo: data['payoutInfo'],
      donationsReceived: List<Map<String, dynamic>>.from(
        data['donationsReceived'] ?? [],
      ),
      adRevenue: data['adRevenue']?.toDouble() ?? 0.0,
      isFollowedByCurrentUser: data['isFollowedByCurrentUser'] ?? false,
    );
  }

  // Factory constructor for placeholder user
  factory UserModel.placeholder(String uid) {
    final now = Timestamp.now();
    return UserModel(
      uid: uid,
      username: 'artbeat_user',
      email: '',
      phoneNumber: '',
      authProvider: 'email',
      isVerified: false,
      fullName: 'ARTbeat User',
      bio: 'No bio available',
      profileImageUrl: '',
      coverImageUrl: '',
      gender: '',
      location: '',
      website: '',
      isOnline: false,
      lastSeen: now,
      createdAt: now,
      updatedAt: now,
      status: '',
      followers: [],
      following: [],
      blockedUsers: [],
      friendRequestsSent: [],
      friendRequestsReceived: [],
      allowMessagesFrom: 'everyone',
      chatMutedUsers: [],
      notificationsEnabled: true,
      emailNotifications: false,
      themePreference: 'system',
      language: 'en',
      privacySettings: {'showEmail': false, 'showBirthDate': false},
      contentFilters: {'matureContent': false},
      posts: [],
      likedPosts: [],
      savedPosts: [],
      comments: [],
      sharedPosts: [],
      favoriteUsers: [],
      isBanned: false,
      banReason: '',
      reportedBy: [],
      reportCount: 0,
      subscriptionStatus: 'free',
      subscriptionExpiry: null,
      payoutInfo: null,
      donationsReceived: [],
      adRevenue: 0.0,
      isFollowedByCurrentUser: false,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'username': username,
    'email': email,
    'phoneNumber': phoneNumber,
    'authProvider': authProvider,
    'isVerified': isVerified,
    'fullName': fullName,
    'bio': bio,
    'profileImageUrl': profileImageUrl,
    'coverImageUrl': coverImageUrl,
    'gender': gender,
    'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    'location': location,
    'website': website,
    'isOnline': isOnline,
    'lastSeen': lastSeen,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'status': status,
    'followers': followers,
    'following': following,
    'blockedUsers': blockedUsers,
    'friendRequestsSent': friendRequestsSent,
    'friendRequestsReceived': friendRequestsReceived,
    'allowMessagesFrom': allowMessagesFrom,
    'chatMutedUsers': chatMutedUsers,
    'notificationsEnabled': notificationsEnabled,
    'emailNotifications': emailNotifications,
    'themePreference': themePreference,
    'language': language,
    'privacySettings': privacySettings,
    'contentFilters': contentFilters,
    'posts': posts,
    'likedPosts': likedPosts,
    'savedPosts': savedPosts,
    'comments': comments,
    'sharedPosts': sharedPosts,
    'favoriteUsers': favoriteUsers,
    'isBanned': isBanned,
    'banReason': banReason,
    'reportedBy': reportedBy,
    'reportCount': reportCount,
    'subscriptionStatus': subscriptionStatus,
    'subscriptionExpiry': subscriptionExpiry,
    'payoutInfo': payoutInfo,
    'donationsReceived': donationsReceived,
    'adRevenue': adRevenue,
  };
}
