# Activity Feed Fix - Community Hub

## Issue

Captures were showing in the **Artbeat Dashboard** live activity feed but NOT in the **Art Community Hub** live activity feed.

## Root Cause

The two screens were using different methods to load activities:

- **Dashboard** (`dashboard_view_model.dart`): Used `getUserActivities()` to load the current user's own activities
- **Community Hub** (`art_community_hub.dart`): Used `getNearbyActivities()` to load activities from nearby users based on geolocation

When you created a capture, it was added to your user activities immediately, so it appeared in the dashboard. However, it might not appear in nearby activities due to:

1. Location filtering being too strict
2. Missing or incorrect location data on the capture
3. Delays in geospatial indexing

## Solution

Updated `art_community_hub.dart` to use the same approach as the dashboard:

1. **Primary**: Load user's own activities using `getUserActivities()`
2. **Secondary**: If fewer than 5 activities, also load nearby activities and combine them
3. **Deduplication**: Remove duplicate activities when combining both sources

This ensures:

- ✅ User's own captures always appear immediately
- ✅ Nearby activities are still shown when available
- ✅ Consistent behavior between dashboard and community hub
- ✅ Better user experience with more reliable activity feed

## Files Modified

- `/Users/kristybock/artbeat/packages/artbeat_community/lib/screens/art_community_hub.dart` (lines 413-472)

## Testing

1. Hot restart the app
2. Create a new capture and mark it as public
3. Check both:
   - Artbeat Dashboard → Live Activity section
   - Art Community Hub → Feed tab → Live Activity section
4. Both should now show your capture activity

## Additional Notes

- The fix maintains backward compatibility with nearby activities
- No changes needed to the `LiveActivityFeed` widget itself
- The dashboard already uses this approach, so we're just making the community hub consistent
