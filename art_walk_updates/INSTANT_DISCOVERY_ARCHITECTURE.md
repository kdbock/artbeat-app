# 🏗️ Instant Discovery Mode - Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Art Walk Dashboard                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Instant Discovery Card                                   │  │
│  │  ┌────────┐  "Instant Discovery"                         │  │
│  │  │ 📡     │  3 artworks nearby                           │  │
│  │  │ Radar  │  [Tap to explore]                            │  │
│  │  └────────┘                                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ User taps card
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Instant Discovery Radar Screen                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Instant Discovery Radar Widget                          │  │
│  │                                                           │  │
│  │         ┌─────────────────────────┐                      │  │
│  │         │    Animated Radar       │                      │  │
│  │         │                         │                      │  │
│  │         │    🎨 ← Art Pin        │                      │  │
│  │         │         (Orange)        │                      │  │
│  │         │                         │                      │  │
│  │         │    📍 ← User Pin       │                      │  │
│  │         │      (Center)           │                      │  │
│  │         │                         │                      │  │
│  │         │    🎨 ← Art Pin        │                      │  │
│  │         │         (Teal)          │                      │  │
│  │         └─────────────────────────┘                      │  │
│  │                                                           │  │
│  │  Bottom Sheet: List of Nearby Art                        │  │
│  │  ┌─────────────────────────────────────────────────┐    │  │
│  │  │ 🎨 Colorful Mural                               │    │  │
│  │  │    by Jane Doe                                  │    │  │
│  │  │    "Very close! Keep going!"          45m →     │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ User taps art pin
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Discovery Capture Modal                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │         [Art Image]                                │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                                                           │  │
│  │  Colorful Mural                                          │  │
│  │  by Jane Doe                                             │  │
│  │                                                           │  │
│  │  📍 45m away                                             │  │
│  │  "Very close! Keep going!"                               │  │
│  │                                                           │  │
│  │  Beautiful street art in downtown...                     │  │
│  │                                                           │  │
│  │  [Mural] [Street Art] [Colorful]                        │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  🎯 Capture Discovery                              │ │  │
│  │  │  (Get within 50m to capture)                       │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ User captures (within 50m)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Success State                                │
│                                                                 │
│                    🎊 Confetti Animation 🎊                     │
│                                                                 │
│                  Discovery Captured!                            │
│                     +20 XP                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Layer                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Screen Layer                               │
│  • InstantDiscoveryRadarScreen                                  │
│  • ArtWalkDashboardScreen                                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Widget Layer                               │
│  • InstantDiscoveryRadar                                        │
│  • DiscoveryCaptureModal                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                              │
│  • InstantDiscoveryService                                      │
│  • RewardsService                                               │
│  • LocationService                                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                 │
│  • Firestore (publicArt collection)                             │
│  • Firestore (users/{userId}/discoveries subcollection)         │
│  • GeoFlutterFire (geospatial queries)                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Service Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│              InstantDiscoveryService                             │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Public Methods:                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ getNearbyArt(userLocation, radius)                         │ │
│  │   → Returns List<PublicArtModel>                           │ │
│  │   → Filters out already discovered art                     │ │
│  │   → Uses GeoFlutterFire for geospatial query              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ watchNearbyArt(userLocation, radius)                       │ │
│  │   → Returns Stream<List<PublicArtModel>>                   │ │
│  │   → Real-time updates as art is added/removed              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ saveDiscovery(userId, art, userLocation, distance)         │ │
│  │   → Saves to users/{userId}/discoveries                    │ │
│  │   → Awards XP (base + bonuses)                             │ │
│  │   → Invalidates cache                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ getProximityMessage(distance)                              │ │
│  │   → Returns contextual message based on distance           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Private Methods:                                                │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ _getDiscoveredArtIds(userId)                               │ │
│  │   → Cached for 5 minutes                                   │ │
│  │   → Returns List<String> of discovered art IDs             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ _awardDiscoveryXP(userId)                                  │ │
│  │   → Base: +20 XP                                           │ │
│  │   → First of day: +50 XP                                   │ │
│  │   → Streak (3+ days): +10 XP per day                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ _getDiscoveryStreak(userId)                                │ │
│  │   → Calculates consecutive days with discoveries           │ │
│  │   → Returns int (streak count)                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Widget Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│              InstantDiscoveryRadar                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  State:                                                          │
│  • nearbyArt: List<PublicArtModel>                              │
│  • userLocation: LatLng                                          │
│  • radiusMeters: double (default: 500)                          │
│  • _sweepController: AnimationController                         │
│                                                                  │
│  Components:                                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Header                                                      │ │
│  │  • Title: "Instant Discovery"                              │ │
│  │  • Subtitle: "X artworks nearby"                           │ │
│  │  • Radius badge: "500m"                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Radar Canvas (CustomPainter)                               │ │
│  │  • Background circle                                       │ │
│  │  • Distance rings (100m, 250m, 500m)                       │ │
│  │  • Animated sweep line                                     │ │
│  │  • Art pins (positioned by distance/bearing)               │ │
│  │  • User pin (center, pulsing)                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Bottom Sheet                                                │ │
│  │  • List of nearby art                                      │ │
│  │  • Distance and proximity message                          │ │
│  │  • Tap to open capture modal                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Methods:                                                        │
│  • _buildRadar() → Radar canvas with animations                 │
│  • _buildUserPin() → Pulsing center pin                         │
│  • _buildArtPin(art) → Positioned art marker                    │
│  • _buildArtMarker(art, distance, isClose) → Styled marker      │
│  • _buildBottomSheet() → List view of nearby art                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│              DiscoveryCaptureModal                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Props:                                                          │
│  • art: PublicArtModel                                           │
│  • userLocation: LatLng                                          │
│  • onCapture: Function                                           │
│                                                                  │
│  State:                                                          │
│  • _isCapturing: bool                                            │
│  • _confettiController: ConfettiController                       │
│                                                                  │
│  Components:                                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Art Image                                                   │ │
│  │  • CachedNetworkImage                                      │ │
│  │  • 200px height                                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Art Details                                                 │ │
│  │  • Title (headline)                                        │ │
│  │  • Artist name (subtitle)                                  │ │
│  │  • Distance indicator                                      │ │
│  │  • Proximity message (color-coded)                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Description & Tags                                          │ │
│  │  • Description text                                        │ │
│  │  • Art type chip                                           │ │
│  │  • Tag chips                                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Capture Button                                              │ │
│  │  • Enabled only within 50m                                 │ │
│  │  • Shows loading state                                     │ │
│  │  • Triggers confetti on success                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Confetti Widget                                             │ │
│  │  • Positioned at top center                                │ │
│  │  • Downward blast                                          │ │
│  │  • 3-second duration                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

```
Firestore
│
├── publicArt (collection)
│   │
│   ├── {artId} (document)
│   │   ├── id: string
│   │   ├── userId: string
│   │   ├── title: string
│   │   ├── description: string
│   │   ├── imageUrl: string
│   │   ├── artistName: string?
│   │   ├── location: GeoPoint
│   │   ├── address: string?
│   │   ├── tags: string[]
│   │   ├── artType: string?
│   │   ├── isVerified: boolean
│   │   ├── viewCount: number
│   │   ├── likeCount: number
│   │   ├── usersFavorited: string[]
│   │   ├── createdAt: Timestamp
│   │   ├── updatedAt: Timestamp
│   │   └── geo: {
│   │       ├── geohash: string (9 chars)
│   │       └── geopoint: GeoPoint
│   │   }
│   │
│   └── ... (more art documents)
│
└── users (collection)
    │
    └── {userId} (document)
        │
        └── discoveries (subcollection)
            │
            ├── {discoveryId} (document)
            │   ├── artId: string
            │   ├── discoveredAt: Timestamp
            │   ├── location: GeoPoint (user's location)
            │   ├── distance: number (meters)
            │   └── xpAwarded: number
            │
            └── ... (more discoveries)
```

---

## Geospatial Query Flow

```
1. User Location
   ├── Latitude: 37.7749
   └── Longitude: -122.4194

2. Create GeoFirePoint
   └── center = GeoFirePoint(GeoPoint(37.7749, -122.4194))

3. Query Firestore
   ├── Collection: publicArt
   ├── Field: geo
   ├── Radius: 0.5 km (500m)
   └── Filter: geo.geohash starts with matching prefix

4. GeoFlutterFire Processing
   ├── Generates geohash for center point
   ├── Calculates geohash prefixes for radius
   ├── Queries Firestore with geohash range
   └── Filters results by exact distance

5. Results
   ├── List of PublicArtModel within radius
   ├── Sorted by distance (closest first)
   └── Filtered to exclude discovered art

6. Display on Radar
   ├── Calculate bearing for each art piece
   ├── Calculate normalized distance (0-1)
   ├── Convert to x/y coordinates
   └── Render pins on radar canvas
```

---

## XP Reward Flow

```
1. User Captures Discovery
   └── saveDiscovery() called

2. Check First Discovery of Day
   ├── Query discoveries for today
   ├── If count == 0:
   │   └── Award +50 XP bonus
   └── Else: Skip bonus

3. Award Base XP
   └── Award +20 XP

4. Calculate Streak
   ├── Query last 7 days of discoveries
   ├── Count consecutive days
   └── If streak >= 3:
       └── Award +10 XP per day

5. Total XP Examples
   ├── Regular discovery: 20 XP
   ├── First of day: 70 XP (20 + 50)
   ├── 3-day streak: 50 XP (20 + 30)
   ├── First of day + 7-day streak: 140 XP (20 + 50 + 70)
   └── Maximum possible: 140 XP
```

---

## Animation Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Animation System                              │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Radar Sweep Animation                                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ AnimationController                                         │ │
│  │  • Duration: 3 seconds                                     │ │
│  │  • Repeat: Infinite                                        │ │
│  │  • Curve: Linear                                           │ │
│  │                                                            │ │
│  │ CustomPainter                                               │ │
│  │  • Draws rotating sweep line                              │ │
│  │  • Gradient from transparent to teal                       │ │
│  │  • Rotates 0° to 360°                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  User Pin Pulse Animation                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ TweenAnimationBuilder                                       │ │
│  │  • Duration: 2 seconds                                     │ │
│  │  • Tween: 0.8 to 1.2 (scale)                              │ │
│  │  • Curve: EaseInOut                                        │ │
│  │  • Repeat: Infinite (reverse)                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Art Pin Pulse Animation (Close)                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ TweenAnimationBuilder                                       │ │
│  │  • Duration: 1.5 seconds                                   │ │
│  │  • Tween: 0.9 to 1.3 (scale)                              │ │
│  │  • Curve: EaseInOut                                        │ │
│  │  • Repeat: Infinite (reverse)                              │ │
│  │  • Condition: distance < 100m                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Confetti Animation                                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ConfettiController                                          │ │
│  │  • Duration: 3 seconds                                     │ │
│  │  • Direction: Downward blast                               │ │
│  │  • Particle count: 50                                      │ │
│  │  • Colors: Teal, Orange, White                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Caching Strategy

```
┌──────────────────────────────────────────────────────────────────┐
│                    Cache Architecture                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Discovered Art IDs Cache                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Key: userId                                                 │ │
│  │ Value: List<String> (art IDs)                              │ │
│  │ TTL: 5 minutes                                              │ │
│  │ Invalidation: On new discovery                             │ │
│  │                                                            │ │
│  │ Benefits:                                                   │ │
│  │  • Reduces Firestore reads by ~80%                         │ │
│  │  • Faster radar loading                                    │ │
│  │  • Lower costs                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Nearby Art Count Cache (Dashboard)                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Key: userLocation (rounded to 100m)                        │ │
│  │ Value: int (count)                                          │ │
│  │ TTL: 5 minutes                                              │ │
│  │ Invalidation: On location change > 100m                     │ │
│  │                                                            │ │
│  │ Benefits:                                                   │ │
│  │  • Dashboard loads instantly                               │ │
│  │  • No query on every map move                              │ │
│  │  • Smooth user experience                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Error Handling

```
┌──────────────────────────────────────────────────────────────────┐
│                    Error Handling Strategy                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Location Errors                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • Permission denied                                         │ │
│  │   → Show permission request dialog                         │ │
│  │   → Provide settings link                                  │ │
│  │                                                            │ │
│  │ • GPS disabled                                              │ │
│  │   → Show "Enable GPS" message                              │ │
│  │   → Provide settings link                                  │ │
│  │                                                            │ │
│  │ • Location unavailable                                      │ │
│  │   → Show "Searching for GPS..." message                    │ │
│  │   → Retry automatically                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Network Errors                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • No internet connection                                    │ │
│  │   → Show "No internet" message                             │ │
│  │   → Offer offline mode (if cached data available)          │ │
│  │                                                            │ │
│  │ • Firestore timeout                                         │ │
│  │   → Show "Loading..." with retry button                    │ │
│  │   → Retry with exponential backoff                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  Data Errors                                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ • No nearby art                                             │ │
│  │   → Show empty state with helpful message                  │ │
│  │   → Suggest trying different location                      │ │
│  │                                                            │ │
│  │ • Invalid art data                                          │ │
│  │   → Log error                                              │ │
│  │   → Skip invalid art                                       │ │
│  │   → Continue with valid art                                │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

This architecture document provides a comprehensive visual overview of the Instant Discovery Mode implementation, showing how all components work together to create a seamless user experience.
