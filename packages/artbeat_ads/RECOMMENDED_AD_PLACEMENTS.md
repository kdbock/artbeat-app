# ArtBeat Ads - 5 Recommended Screens for Ad Placement

Based on user behavior (art discovery, capture, art walks, events, community), here are the **5 best screens** for ad placement ranked by traffic priority.

---

## 🏆 **Screen 1: Home Dashboard** (HIGH TRAFFIC)
**Route**: `/dashboard` | **Component**: `ArtbeatDashboardScreen`

**Why**: User entry point after login. Users spend 3-5 min exploring featured content, progress, and recommendations.

### **5 Ad Placements**:

| Slot | Position | Type | Size | Context | Revenue |
|------|----------|------|------|---------|---------|
| **1** | Top banner (hero) | Carousel | Big (1920×400) | Above progress card - rotates every 4s | ⭐⭐⭐⭐⭐ |
| **2** | Between progress & browse | Native card | Small (300×200) | Seamless blend with dashboard UI | ⭐⭐⭐⭐⭐ |
| **3** | Browse carousel footer | Horizontal scroll | Mixed (varies) | Ad slides within browse carousel | ⭐⭐⭐⭐ |
| **4** | Below leaderboard | Widget banner | Small (300×100) | Leaderboard engagement + ads | ⭐⭐⭐⭐ |
| **5** | Sticky header (scroll) | Dismissible banner | Small (full width × 60) | Appears when scrolling down | ⭐⭐⭐ |

**Expected Metrics**:
- Impressions/month: 150k-200k
- CTR: 40-60%
- Avg session time: 3-5 min
- Best Size: **Big Square** for premium slots

**Integration Point**:
```dart
// In ArtbeatDashboardScreen build()
SingleChildScrollView(
  controller: _scrollController,
  child: Column(
    children: [
      // Slot 1: Hero banner
      AdCarouselWidget(
        zone: LocalAdZone.home,
        height: 400,
      ),
      SizedBox(height: 16),
      
      // Slot 2: Between sections
      AdCardWidget(zone: LocalAdZone.home),
      
      // ... browse section
      _buildBrowseWithAds(), // Slot 3 injected here
      
      // Slot 4: Below leaderboard
      LeaderboardPreviewWidget(),
      AdSmallBannerWidget(zone: LocalAdZone.home),
    ],
  ),
)
```

---

## 🎟️ **Screen 2: Events Dashboard** (HIGH TRAFFIC)
**Route**: `/local` → `events/dashboard` | **Component**: `EventsDashboardScreen`

**Why**: Highest purchase intent. Users actively searching for events to attend. 2-4 min high-engagement browsing.

### **5 Ad Placements**:

| Slot | Position | Type | Size | Context | Revenue |
|------|----------|------|------|---------|---------|
| **1** | Top sticky banner | Featured carousel | Big (full width × 120) | "Featured Events" rotates auto | ⭐⭐⭐⭐⭐ |
| **2** | Between category chips | Native ad-card | Small (full width × 180) | Promoted event (looks like event card) | ⭐⭐⭐⭐⭐ |
| **3** | Interspersed in list | Event-style card | Medium (full width × 200) | Every 5th event position | ⭐⭐⭐⭐⭐ |
| **4** | Category empty state | Call-to-action | Big (full width × 150) | "No results? Explore featured" | ⭐⭐⭐⭐ |
| **5** | List bottom (load more) | Banner | Small (full width × 60) | "More events nearby" ad banner | ⭐⭐⭐ |

**Expected Metrics**:
- Impressions/month: 100k-150k
- CTR: 45-65%
- Avg session time: 2-4 min
- Best Size: **Big Square** for highest engagement

**Integration Point**:
```dart
// In EventsDashboardScreen
ListView.builder(
  itemCount: events.length + adSlots.length,
  itemBuilder: (context, index) {
    // Slot 1: Sticky header
    if (index == 0) {
      return Column(
        children: [
          AdCarouselWidget(zone: LocalAdZone.events),
          _buildCategoryChips(),
          
          // Slot 2: Between chips and list
          AdCardWidget(zone: LocalAdZone.events),
        ],
      );
    }
    
    // Slot 3: Interspersed ads (every 5th event)
    if ((index - 2) % 5 == 0) {
      return AdEventStyleCard(zone: LocalAdZone.events);
    }
    
    return EventCard(event: events[index - countOfAdsAbove]);
  },
)
```

---

## 🗺️ **Screen 3: Art Walk Dashboard** (HIGH TRAFFIC)
**Route**: `/art-walk/dashboard` | **Component**: `ArtWalkDashboardScreen`

**Why**: Gamification + social engagement. Users on active art walks (high intent). 4-6 min immersive experience.

### **5 Ad Placements**:

| Slot | Position | Type | Size | Context | Revenue |
|------|----------|------|------|---------|---------|
| **1** | Map top overlay | Badge/banner | Small (200×80) | "Nearby Experiences" ad float | ⭐⭐⭐⭐⭐ |
| **2** | Art walk card footer | Native ad card | Small (300×120) | Related galleries/studios ad | ⭐⭐⭐⭐⭐ |
| **3** | Between checkpoints | Promotion banner | Medium (full width × 100) | "Unlock more locations" sponsored | ⭐⭐⭐⭐ |
| **4** | Completion screen | Celebration card | Big (full width × 200) | "Share & discover more" ad | ⭐⭐⭐⭐ |
| **5** | Leaderboard sidebar | Vertical banner | Small (120×300) | Side widget (if applicable) | ⭐⭐⭐ |

**Expected Metrics**:
- Impressions/month: 80k-120k
- CTR: 35-55%
- Avg session time: 4-6 min
- Best Size: **Big Square** for immersive experience

**Integration Point**:
```dart
// In ArtWalkDashboardScreen
Stack(
  children: [
    GoogleMap(...),
    
    // Slot 1: Top overlay badge
    Positioned(
      top: 16, right: 16,
      child: AdBadgeWidget(zone: LocalAdZone.featured),
    ),
    
    // Slot 2: Card footer
    Positioned(
      bottom: 16, left: 0, right: 0,
      child: Column(
        children: [
          ArtWalkCard(...),
          AdNativeCardWidget(zone: LocalAdZone.featured),
        ],
      ),
    ),
  ],
)
```

---

## 👥 **Screen 4: Community Feed** (MEDIUM-HIGH TRAFFIC)
**Route**: `/community` | **Component**: `ArtistCommunityFeedScreen`

**Why**: Social engagement + comments. Users spend 2-3 min browsing posts. Less purchase-intent but high engagement.

### **5 Ad Placements**:

| Slot | Position | Type | Size | Context | Revenue |
|------|----------|------|------|---------|---------|
| **1** | Sticky feed header | Dismissible banner | Small (full width × 80) | "Trending in your community" | ⭐⭐⭐⭐ |
| **2** | Between posts | Native post-style ad | Medium (full width × 160) | Blends with feed posts | ⭐⭐⭐⭐ |
| **3** | Create compose area | Call-to-action card | Small (full width × 120) | "Boost your post" sponsorship | ⭐⭐⭐ |
| **4** | Feed end state | Bottom banner | Small (full width × 100) | "No more posts? Discover ads" | ⭐⭐⭐ |
| **5** | Leaderboard embed | Sidebar card | Small (160×240) | Community leaders + ads | ⭐⭐ |

**Expected Metrics**:
- Impressions/month: 70k-100k
- CTR: 25-40%
- Avg session time: 2-3 min
- Best Size: **Both** - mix of small banners and big squares

**Integration Point**:
```dart
// In ArtistCommunityFeedScreen
RefreshIndicator(
  child: ListView.builder(
    itemCount: posts.length + 5, // +5 for ad slots
    itemBuilder: (context, index) {
      // Slot 1: Sticky header
      if (index == 0) {
        return AdStickyHeaderWidget(zone: LocalAdZone.community);
      }
      
      // Slot 2: Interspersed ads (every 6th post)
      if ((index - 1) % 6 == 0) {
        return AdPostStyleWidget(zone: LocalAdZone.community);
      }
      
      // Slot 3: After create section
      if (index == 2) {
        return Column(
          children: [
            CreateComposeWidget(),
            AdCTACardWidget(zone: LocalAdZone.community),
          ],
        );
      }
      
      return PostCard(post: posts[index]);
    },
  ),
)
```

---

## 🎨 **Screen 5: Artwork Browse Grid** (MEDIUM TRAFFIC)
**Route**: `/artwork/browse` | **Component**: `ArtworkBrowseScreen` or Gallery Grid

**Why**: Discovery browsing. Users exploring artists' work. 2-3 min lower-intent browsing.

### **5 Ad Placements**:

| Slot | Position | Type | Size | Context | Revenue |
|------|----------|------|------|---------|---------|
| **1** | Grid header banner | Section header | Small (full width × 80) | "Featured Artwork" section | ⭐⭐⭐⭐ |
| **2** | Between grid items | Grid ad card | Medium (grid cell × 200) | Ad styled as artwork card | ⭐⭐⭐⭐ |
| **3** | Filter/sort section | Native ad card | Small (full width × 120) | Near filter options | ⭐⭐⭐ |
| **4** | Bottom load-more | Promotional banner | Small (full width × 100) | "Load more" or "Discover ads" | ⭐⭐⭐ |
| **5** | Favorites sidebar | Vertical card | Small (150×150) | "Popular this week" ad | ⭐⭐ |

**Expected Metrics**:
- Impressions/month: 90k-130k
- CTR: 20-35%
- Avg session time: 2-3 min
- Best Size: **Both** - mix of banner and square formats

**Integration Point**:
```dart
// In ArtworkBrowseScreen
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
  ),
  itemCount: artworks.length + adSlots.length,
  itemBuilder: (context, index) {
    // Slot 1: Header
    if (index == 0) {
      return GridView.count(
        crossAxisCount: 2,
        children: [
          AdSectionHeaderWidget(),
          ...
        ],
      );
    }
    
    // Slot 2: Interspersed ads (every 6th item)
    if ((index - 1) % 6 == 0) {
      return AdGridCardWidget(zone: LocalAdZone.artists);
    }
    
    return ArtworkCard(artwork: artworks[index]);
  },
)
```

---

## 📊 **Ad Format Distribution by Screen**

| Screen | Big Square Ads | Small Banner Ads | Monthly Revenue |
|--------|---|---|---|
| **Home Dashboard** | 2-3 | 2-3 | $600-$1,200 |
| **Events Dashboard** | 3-4 | 1-2 | $500-$1,000 |
| **Art Walk Dashboard** | 3 | 2 | $400-$800 |
| **Community Feed** | 1-2 | 3-4 | $200-$400 |
| **Artwork Browse** | 1-2 | 2-3 | $150-$300 |

**Total Revenue Potential**: $1,850-$3,700/month from 5 screens

---

## 🎯 **Ad Format & Pricing Strategy**

### **Small Banner Ads**
- **Best for**: Budget-conscious advertisers, subtle integration
- **Pricing**: $0.99/week, $1.99/month, $4.99/3-months
- **Placement**: Between content, sidebars, footers
- **Expected ROI**: 25-35% CTR

### **Big Square Ads**  
- **Best for**: Premium advertisers, maximum visibility
- **Pricing**: $1.99/week, $3.99/month, $9.99/3-months
- **Placement**: Hero slots, dedicated spaces, top placements
- **Expected ROI**: 45-65% CTR

---

## 🚀 **Implementation Order**

1. **Week 1-2**: Implement Screen 1 (Home) - 5 ad slots
2. **Week 2-3**: Implement Screen 2 (Events) - 5 ad slots
3. **Week 3-4**: Implement Screen 3 (Art Walk) - 5 ad slots
4. **Week 4-5**: Implement Screen 4 (Community) - 5 ad slots
5. **Week 5-6**: Implement Screen 5 (Artwork) - 5 ad slots

**Total**: 25 ad placement slots across 5 high-impact screens

---

## 📋 **Reusable Ad Components**

Create these components in `lib/src/widgets/`:

```
ad_widgets/
├── ad_carousel_widget.dart        (auto-rotating hero)
├── ad_card_widget.dart             (native card style)
├── ad_event_style_card.dart        (event card clone)
├── ad_post_style_widget.dart       (post card clone)
├── ad_sticky_header_widget.dart    (dismissible banner)
├── ad_grid_card_widget.dart        (grid item style)
├── ad_badge_widget.dart            (floating badge)
├── ad_cta_card_widget.dart         (call-to-action)
└── ad_small_banner_widget.dart     (horizontal banner)
```

Each widget:
- Queries `AdPricingMatrix` by zone/priority
- Displays dynamic ad content from Firestore
- Tracks impressions/clicks
- Supports native styling per zone

---

## ✅ **Success Metrics**

Track these KPIs per screen:

- **Impressions**: Target 500+ impressions/slot/month
- **CTR**: Target 30-60% depending on priority
- **Revenue/Month**: Track by screen & priority tier
- **User Engagement**: Monitor bounce rate after ad click
- **Ad Quality**: Maintain <2% spam reports

---

## 🎨 **Design Principles**

✅ **Do**:
- Match native UI styling per zone
- Use clear "Ad" / "Sponsored" badges
- Provide dismiss/close options
- Rotate ads to prevent blindness
- Test on real devices for UX

❌ **Don't**:
- Auto-play video in community feed
- Use intrusive interstitials
- Misleading CTAs ("Win Now!")
- Ads that break scroll flow
- More than 1 ad per 3-4 content items

---

## Next Steps

1. **Start with Screen 1 (Home Dashboard)**
   - Create `ad_carousel_widget.dart`
   - Integrate into `ArtbeatDashboardScreen`
   - Test with sample ads
   
2. **Monitor performance**
   - Track impressions/CTR
   - Adjust placement based on data
   
3. **Scale to other screens**
   - Reuse components
   - Adjust sizing per screen context

**Ready to start?** Pick Screen 1 and begin integration. 🚀
