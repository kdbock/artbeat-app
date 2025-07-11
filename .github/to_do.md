artbeat_header.dart
Implement search function on header


fluid_dashboard_screen
Art Around You section
Art Walks Near You button should connect to: /Users/kristybock/artbeat/packages/artbeat_art_walk/lib/src/screens/art_walk_dashboard_screen.dart

Map is missing sync to user location icon, map should connect to: /Users/kristybock/artbeat/packages/artbeat_art_walk/lib/src/screens/art_walk_dashboard_screen.dart

Quick Actions Section
Capture Art should connect to /Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/enhanced_capture_dashboard_screen.dart

Recent Captures section
All captures, not just user uploaded should be listed here, up to 20. It is currently set to user captures and not all public captures. The button next to recent captures should say Find Art and connect to /Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/enhanced_capture_dashboard_screen.dart

When user taps on capture image or text, nothing happens. Does not connect with capture card should have capture details, image, and button to create art walk.

Featured Artist section
User taps view all - app reloads does not connect with artist_list
When user taps artist card, screen loads, but does not load within the app architecture. Loads without app header and bottom navigation

Community Highlights section
User taps View All, community_dashboard loads but outside of the app architecture, there is no header or bottom navigation. 

Community cards should show uploaded image, and user avatar should show 

art_walk_dashboard_screen
Local Art Map section, does not connect to art walk map screen

Your Captures section should be Local Captures
Capture cards slider View All button should go to public_captures_screen

Your Art Walks section should be Local Art Walks
View all should connect to art walk list screen

User taps created art walk and nothing happens in the list under Your Art Walks. 

community_dashboard
Feed, trending, portfolios, and studios section is above header and behind header, needs brought down beneath the submit artwork for critique button

art_walk_map_screen
Use regular header and bottom navigation
Search by zip code bar

Map widget with capture icons and sync to user location button
Large center Create Art Walk button beneath

Local Public Art
Load capture cards in range as slider

Local Art Walks section
Load art walk cards in range as list

events_dashboard

artist_dashboard
Add total gift value
Add Sponsorships value


artbeat_drawer
Edit artist profile is not connected to artist_profile_edit_screen.dart
View Public Profile is not connected to artist_public_profile_screen
My Artwork is not connected to artist uploaded artwork
Upload Artwork is not connected to packages/artbeat_artwork/lib/src/screens/enhanced_artwork_upload_screen.dart
Artist Analytics is not connected to packages/artbeat_artist/lib/src/screens/analytics_dashboard_screen.dart
Artist Approved Ads is not connected to packages/artbeat_artist/lib/src/screens/artist_approved_ads_screen.dart

Bottom navigation:
Events  is not connected to events_dashboad

Capture Details
All capture detail cards need Create Art Walk button, and an ad