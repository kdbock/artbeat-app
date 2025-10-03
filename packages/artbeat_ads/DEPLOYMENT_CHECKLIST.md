# Zone-Based Ad System - Deployment Checklist

## 🚀 **Pre-Deployment Setup**

Before deploying the zone-based ad system to production, complete these steps:

---

## ✅ **Step 1: Update Firestore Security Rules**

**Status:** ✅ **COMPLETE** - Rules already updated in `/firestore.rules`

The title sponsorship rules have been added. Deploy them:

```bash
firebase deploy --only firestore:rules
```

**Expected Output:**

```
✔  Deploy complete!
```

**Verify:** Check Firebase Console → Firestore Database → Rules tab

---

## ✅ **Step 2: Create Firestore Indexes**

**Status:** ⚠️ **ACTION REQUIRED**

### **Option A: Automatic Deployment (Recommended)**

Deploy the indexes using the `firestore.indexes.json` file:

```bash
firebase deploy --only firestore:indexes
```

**Expected Output:**

```
✔  firestore: deployed indexes in firestore.indexes.json successfully
```

**Build Time:** 5-15 minutes depending on existing data

### **Option B: Manual Creation**

If automatic deployment fails, create indexes manually:

1. Run the app and trigger ad queries
2. Firebase will show errors with direct links
3. Click each link to auto-create the index
4. Wait for indexes to build (2-5 minutes each)

### **Required Indexes (9 total):**

#### **Ads Collection (4 indexes)**

- ✅ Zone-based queries: `zone + status + startDate + endDate`
- ✅ Location-based queries: `location + status + startDate + endDate`
- ✅ Owner queries: `ownerId + startDate`
- ✅ Active count: `location + status + endDate`

#### **Title Sponsorships Collection (5 indexes)**

- ✅ Active sponsor: `status + startDate + endDate`
- ✅ Conflict check: `status + startDate`
- ✅ By sponsor: `sponsorId + createdAt`
- ✅ Pending: `status + createdAt`
- ✅ Expire old: `status + endDate`

**Verify:** Firebase Console → Firestore Database → Indexes tab

---

## ✅ **Step 3: Test Ad Queries**

Run these tests to ensure indexes are working:

### **Test 1: Zone-Based Ads**

```dart
// Test in your app or Firebase Console
final service = SimpleAdService();
final ads = await service.getAdsByZone(AdZone.homeDiscovery);
print('Found ${ads.length} ads in Home & Discovery zone');
```

**Expected:** No "requires an index" error

### **Test 2: Title Sponsorship**

```dart
final sponsorService = TitleSponsorshipService();
final sponsor = await sponsorService.getActiveSponsor();
print('Active sponsor: ${sponsor?.sponsorName ?? "None"}');
```

**Expected:** Returns null or active sponsor (no errors)

### **Test 3: User Ads**

```dart
final myAds = await service.getAdsByOwner(currentUserId);
print('User has ${myAds.length} ads');
```

**Expected:** Returns user's ads without errors

---

## ✅ **Step 4: Verify Ad Placements**

Check that ads are displaying correctly in all zones:

### **Screens to Test:**

- [ ] **Dashboard** (Home & Discovery zone) - 6 placements
- [ ] **Community Hub** (Community & Social zone) - 1 placement
- [ ] **Events Dashboard** (Events zone) - 1 placement
- [ ] **Capture Dashboard** (Art Walks zone) - 4 placements

### **What to Check:**

1. Ads load without errors
2. Correct zone ads appear in each screen
3. Ad rotation works (different ads on refresh)
4. Empty state shows when no ads available
5. Click tracking works (if implemented)

---

## ✅ **Step 5: Test Ad Creation Flow**

Test the new zone-based ad creation:

1. Navigate to ad creation screen
2. Verify zone dropdown shows all 5 zones with icons and pricing
3. Select different zones and verify info card updates
4. Verify cost calculation: `zone price × days`
5. Create a test ad and verify it saves with `zone` field
6. Check Firestore to confirm both `zone` and `location` fields are set

**Expected Result:** Ad created successfully with zone data

---

## ✅ **Step 6: Test Title Sponsorship**

If implementing title sponsorship:

1. Create a test sponsorship request
2. Verify it appears in pending sponsorships
3. Approve as admin
4. Verify it displays in splash screen and drawer
5. Check impression tracking works

---

## ✅ **Step 7: Monitor Performance**

After deployment, monitor these metrics:

### **Firebase Console Checks:**

1. **Firestore Usage**

   - Check read/write counts
   - Verify indexes are being used (no full collection scans)

2. **Error Logs**

   - Look for "requires an index" errors
   - Check for permission denied errors

3. **Performance**
   - Query latency should be <100ms
   - No timeout errors

### **App Analytics:**

- Ad impression counts
- Zone performance (which zones get most views)
- Click-through rates
- Revenue by zone

---

## 🔧 **Troubleshooting**

### **Issue: "Query requires an index" error**

**Solution:**

1. Click the error link to create the index
2. Wait 2-5 minutes for index to build
3. Retry the query

### **Issue: "Permission denied" error**

**Solution:**

1. Verify Firestore rules are deployed
2. Check user is authenticated
3. Verify user has correct permissions (owner or admin)

### **Issue: Ads not displaying**

**Solution:**

1. Check ad status is "approved"
2. Verify startDate ≤ now ≤ endDate
3. Check zone matches the placement
4. Verify indexes are built

### **Issue: Wrong ads showing in zone**

**Solution:**

1. Check `ZoneAdPlacementWidget` has correct `zone` parameter
2. Verify ad's `zone` field is set correctly in Firestore
3. Check legacy ads have proper zone mapping via `effectiveZone`

---

## 📊 **Post-Deployment Checklist**

After 24 hours of production use:

- [ ] No Firestore errors in logs
- [ ] All indexes showing as "Enabled" in console
- [ ] Ad impressions being tracked
- [ ] Zone-based queries performing well (<100ms)
- [ ] Users can create ads successfully
- [ ] Ads displaying in correct zones
- [ ] Revenue tracking working
- [ ] No security rule violations

---

## 🎯 **Success Criteria**

The deployment is successful when:

✅ All 9 indexes are built and enabled
✅ Firestore rules deployed without errors
✅ Ads display in all 5 zones
✅ Ad creation flow works with zone selection
✅ No "requires an index" errors in logs
✅ Query performance <100ms
✅ Title sponsorship (if implemented) displays correctly
✅ Backward compatibility maintained (legacy ads still work)

---

## 📞 **Support**

If you encounter issues:

1. Check `/packages/artbeat_ads/FIRESTORE_SETUP.md` for detailed index requirements
2. Review `/packages/artbeat_ads/ZONE_MIGRATION_COMPLETE.md` for implementation details
3. Check Firebase Console logs for specific errors
4. Verify all indexes are in "Enabled" state (not "Building" or "Error")

---

## 🎉 **Deployment Complete!**

Once all steps are complete, your zone-based ad system is live and ready to generate revenue!

**Next Steps:**

- Monitor ad performance by zone
- Adjust pricing based on demand
- Add more ad placements to remaining screens
- Implement title sponsorship purchase flow (if not done)
- Create admin dashboard for ad management
