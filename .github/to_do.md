To Do List
Create a specific header for each project except core. 

Headers use Limelight font.

Header	Hex Code	RGB.  Text/Icon Color
artbeat_admin	#8c52ff	(140, 82, 255) #00bf63
artbeat_ads	#7e63f3	(126, 99, 243) #00bf63
artbeat_art_walk	#7075e7	(112, 117, 231) #00bf63
artbeat_artist	#6286db	(98, 134, 219) #00bf63
artbeat_artwork	#5497cf	(84, 151, 207) #00bf63
artbeat_auth	#46a8c3	(70, 168, 195) #00bf63
artbeat_capture	#38b9b7	(56, 185, 183) #8c52ff
artbeat_community	#2acaaa	(42, 202, 170) #8c52ff
artbeat_events	#1cdba0	(28, 219, 160) #8c52ff
artbeat_messaging	#0eec96	(14, 236, 150) #8c52ff
artbeat_profile	#00fd8a	(0, 253, 138) #8c52ff
artbeat_settings	#00bf63	(0, 191, 99) #8c52ff

Header Items description:
- drawer icon: to package drawer for screens within the package
- Header Title
- Back Button (for screens within the package)
- Menu Icon Discvoer & Connect content - search app
- Search Icon: search_icon.svg
- Chat icon: for artbeat_messaging entry point
- Developer Icon: search current implementation of developer icon

Here’s a review of the header in fluid_dashboard_screen.dart:

Header Items (AppBar/EnhancedUniversalHeader)
Title: "ARTbeat" (centered, not a button)
Search Icon: (showSearch: true)
Taps: Navigates to /search
Profile Icon: (triggered by onProfilePressed)
Taps: Opens the profile menu (bottom sheet with profile navigation options)
Menu Icon: (triggered by onMenuPressed)
Taps: Opens the navigation drawer
Messages Icon: (in actions, with unread badge if needed)
Taps: Calls viewModel.showMessagingMenu(context) (likely opens a messaging menu or screen)
Profile Menu (opened from profile icon)
Find Artists: /artist/search
Trending: /trending
Browse Artwork: /artwork/featured
Local Scene: /local
My Profile: /profile
All header actions are either navigation to a named route or open a menu/bottom sheet for further navigation.