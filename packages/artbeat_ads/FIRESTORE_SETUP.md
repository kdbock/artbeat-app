# Firestore Rules & Indexes - Zone-Based Ad System

## Overview

This document outlines the Firestore security rules and composite indexes required for the zone-based advertising system to function properly.

---

## 🔒 **Firestore Security Rules**

### **Current Status: ✅ Mostly Complete**

The existing rules in `/firestore.rules` already cover most ad functionality. However, we need to add rules for the new **Title Sponsorship** collection.

### **1. Existing Ad Rules (Lines 757-798)**

These rules are already in place and work for both legacy location-based and new zone-based ads:

```javascript
// Ads collections - allow read access for all authenticated users
match /ads/{adId} {
  allow read, list: if isAuthenticated();
  allow create: if isAuthenticated();
  allow update, delete: if isAuthenticated() && (
    request.auth.uid == resource.data.ownerId ||
    isAdmin(request.auth.uid)
  );
}

// Artist approved ads collection
match /artist_approved_ads/{adId} {
  allow read, list: if isAuthenticated();
  allow create: if isAuthenticated() && (
    isArtist(request.auth.uid) ||
    isAdmin(request.auth.uid)
  );
  allow update, delete: if isAuthenticated() && (
    request.auth.uid == resource.data.ownerId ||
    isAdmin(request.auth.uid)
  );
}

// Ad analytics collection
match /ad_analytics/{analyticsId} {
  allow read: if isAuthenticated() && (
    isAdmin(request.auth.uid)
  );
  allow create: if isAuthenticated();
  allow update, delete: if isAuthenticated() && isAdmin(request.auth.uid);
}
```

**Status:** ✅ **No changes needed** - These rules support both `location` and `zone` fields.

---

### **2. NEW: Title Sponsorship Rules (NEEDS TO BE ADDED)**

Add these rules after the ad analytics section (around line 799):

```javascript
// Title Sponsorships - Premium $5,000/month app-wide sponsorship
match /title_sponsorships/{sponsorshipId} {
  // Anyone can read active sponsorships (for display)
  allow read: if isAuthenticated();

  // Anyone can create a sponsorship request
  allow create: if isAuthenticated() &&
    request.auth.uid == request.resource.data.sponsorId;

  // Only sponsor owner or admin can update
  allow update: if isAuthenticated() && (
    request.auth.uid == resource.data.sponsorId ||
    isAdmin(request.auth.uid)
  );

  // Only admin can delete
  allow delete: if isAuthenticated() && isAdmin(request.auth.uid);

  // Allow listing for admins and sponsor owners
  allow list: if isAuthenticated() && (
    isAdmin(request.auth.uid) ||
    request.auth.uid == resource.data.sponsorId
  );
}
```

**Action Required:** ✏️ **Add these rules to `/firestore.rules`**

---

## 📊 **Firestore Composite Indexes**

Firestore requires composite indexes for queries that filter on multiple fields or combine `where()` with `orderBy()`.

### **Index Requirements**

#### **1. Zone-Based Ad Queries** ⚠️ **REQUIRED**

**Query:** `getAdsByZone()` in `simple_ad_service.dart` (lines 233-240)

```dart
_adsRef
  .where('zone', isEqualTo: zone.index)
  .where('status', isEqualTo: AdStatus.approved.index)
  .where('startDate', isLessThanOrEqualTo: now)
  .where('endDate', isGreaterThan: now)
```

**Index Required:**

- **Collection:** `ads`
- **Fields:**
  - `zone` (Ascending)
  - `status` (Ascending)
  - `startDate` (Ascending)
  - `endDate` (Ascending)

---

#### **2. Location-Based Ad Queries** ⚠️ **REQUIRED** (Legacy Support)

**Query:** `getAdsByLocation()` in `simple_ad_service.dart` (lines 218-224)

```dart
_adsRef
  .where('location', isEqualTo: location.index)
  .where('status', isEqualTo: AdStatus.approved.index)
  .where('startDate', isLessThanOrEqualTo: now)
  .where('endDate', isGreaterThan: now)
```

**Index Required:**

- **Collection:** `ads`
- **Fields:**
  - `location` (Ascending)
  - `status` (Ascending)
  - `startDate` (Ascending)
  - `endDate` (Ascending)

---

#### **3. Owner Ad Queries** ⚠️ **REQUIRED**

**Query:** `getAdsByOwner()` in `simple_ad_service.dart` (lines 253-257)

```dart
_adsRef
  .where('ownerId', isEqualTo: ownerId)
  .orderBy('startDate', descending: true)
```

**Index Required:**

- **Collection:** `ads`
- **Fields:**
  - `ownerId` (Ascending)
  - `startDate` (Descending)

---

#### **4. Active Ads Count Query** ⚠️ **REQUIRED**

**Query:** `getActiveAdsCount()` in `simple_ad_service.dart` (lines 458-464)

```dart
_adsRef
  .where('location', isEqualTo: location.index)
  .where('status', isEqualTo: AdStatus.approved.index)
  .where('endDate', isGreaterThan: Timestamp.now())
```

**Index Required:**

- **Collection:** `ads`
- **Fields:**
  - `location` (Ascending)
  - `status` (Ascending)
  - `endDate` (Ascending)

---

#### **5. Title Sponsorship - Active Sponsor Query** ⚠️ **REQUIRED**

**Query:** `getActiveSponsor()` in `title_sponsorship_service.dart` (lines 17-22)

```dart
_sponsorshipsCollection
  .where('status', isEqualTo: SponsorshipStatus.active.index)
  .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
  .where('endDate', isGreaterThan: Timestamp.fromDate(now))
```

**Index Required:**

- **Collection:** `title_sponsorships`
- **Fields:**
  - `status` (Ascending)
  - `startDate` (Ascending)
  - `endDate` (Ascending)

---

#### **6. Title Sponsorship - Conflict Check Query** ⚠️ **REQUIRED**

**Query:** `_checkForConflicts()` in `title_sponsorship_service.dart` (lines 125-134)

```dart
_sponsorshipsCollection
  .where('status', whereIn: [active, pending])
  .where('startDate', isLessThan: Timestamp.fromDate(endDate))
```

**Index Required:**

- **Collection:** `title_sponsorships`
- **Fields:**
  - `status` (Ascending)
  - `startDate` (Ascending)

---

#### **7. Title Sponsorship - By Sponsor Query** ⚠️ **REQUIRED**

**Query:** `getSponsorshipsBySponsor()` in `title_sponsorship_service.dart` (lines 211-214)

```dart
_sponsorshipsCollection
  .where('sponsorId', isEqualTo: sponsorId)
  .orderBy('createdAt', descending: true)
```

**Index Required:**

- **Collection:** `title_sponsorships`
- **Fields:**
  - `sponsorId` (Ascending)
  - `createdAt` (Descending)

---

#### **8. Title Sponsorship - Pending Sponsorships Query** ⚠️ **REQUIRED**

**Query:** `getPendingSponsorships()` in `title_sponsorship_service.dart` (lines 254-257)

```dart
_sponsorshipsCollection
  .where('status', isEqualTo: SponsorshipStatus.pending.index)
  .orderBy('createdAt', descending: true)
```

**Index Required:**

- **Collection:** `title_sponsorships`
- **Fields:**
  - `status` (Ascending)
  - `createdAt` (Descending)

---

#### **9. Title Sponsorship - Expire Old Sponsorships Query** ⚠️ **REQUIRED**

**Query:** `expireOldSponsorships()` in `title_sponsorship_service.dart` (lines 290-293)

```dart
_sponsorshipsCollection
  .where('status', isEqualTo: SponsorshipStatus.active.index)
  .where('endDate', isLessThan: Timestamp.fromDate(now))
```

**Index Required:**

- **Collection:** `title_sponsorships`
- **Fields:**
  - `status` (Ascending)
  - `endDate` (Ascending)

---

## 🚀 **How to Create Indexes**

### **Method 1: Automatic (Recommended)**

1. Run the app and trigger each query
2. Firebase will show an error with a direct link to create the index
3. Click the link and Firebase Console will auto-create the index
4. Wait 2-5 minutes for the index to build

### **Method 2: Manual via Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. Enter the collection name and fields as specified above
6. Click **Create**

### **Method 3: Using firestore.indexes.json**

Create a file at `/firestore.indexes.json` with the following content:

```json
{
  "indexes": [
    {
      "collectionGroup": "ads",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "zone", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "ASCENDING" },
        { "fieldPath": "endDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "ads",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "location", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "ASCENDING" },
        { "fieldPath": "endDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "ads",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "ownerId", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "ads",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "location", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "endDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "title_sponsorships",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "ASCENDING" },
        { "fieldPath": "endDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "title_sponsorships",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "title_sponsorships",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "sponsorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "title_sponsorships",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "title_sponsorships",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "endDate", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Then deploy with:

```bash
firebase deploy --only firestore:indexes
```

---

## 📋 **Implementation Checklist**

### **Firestore Rules**

- [x] ✅ Ad collection rules (already exist)
- [x] ✅ Ad analytics rules (already exist)
- [ ] ⚠️ **Add title sponsorship rules** (see section 2 above)

### **Firestore Indexes**

- [ ] ⚠️ **Zone-based ad queries** (4 fields)
- [ ] ⚠️ **Location-based ad queries** (4 fields) - Legacy support
- [ ] ⚠️ **Owner ad queries** (2 fields)
- [ ] ⚠️ **Active ads count** (3 fields)
- [ ] ⚠️ **Title sponsorship - active sponsor** (3 fields)
- [ ] ⚠️ **Title sponsorship - conflict check** (2 fields)
- [ ] ⚠️ **Title sponsorship - by sponsor** (2 fields)
- [ ] ⚠️ **Title sponsorship - pending** (2 fields)
- [ ] ⚠️ **Title sponsorship - expire old** (2 fields)

**Total Indexes Required:** 9

---

## ⚡ **Performance Considerations**

### **Index Build Time**

- Small collections (<1000 docs): 2-5 minutes
- Medium collections (1000-10000 docs): 5-15 minutes
- Large collections (>10000 docs): 15-60 minutes

### **Query Performance**

With proper indexes:

- Zone-based ad queries: **<100ms**
- Title sponsorship queries: **<50ms**
- Owner ad queries: **<100ms**

Without indexes:

- Queries will **fail** with "requires an index" error

---

## 🔍 **Testing Indexes**

After creating indexes, test each query:

```dart
// Test zone-based ads
final ads = await SimpleAdService().getAdsByZone(AdZone.homeDiscovery);

// Test title sponsorship
final sponsor = await TitleSponsorshipService().getActiveSponsor();

// Test owner ads
final myAds = await SimpleAdService().getAdsByOwner(userId);
```

If any query fails with "requires an index" error, create the missing index using the error link.

---

## 📚 **Additional Resources**

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Best Practices for Firestore](https://firebase.google.com/docs/firestore/best-practices)

---

## ✅ **Summary**

**What Needs to Be Done:**

1. ✏️ **Add title sponsorship rules** to `/firestore.rules` (5 minutes)
2. ⚠️ **Create 9 composite indexes** (automatic via error links or manual via console)
3. ✅ **Test all queries** to ensure indexes are working

**Estimated Setup Time:** 30-45 minutes (including index build time)

Once complete, the zone-based ad system will be fully operational with proper security and performance! 🎉
