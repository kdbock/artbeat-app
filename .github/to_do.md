Header & Navigation Standardization Checklist

Task: For every screen in each package, update to MainLayout + EnhancedUniversalHeader (unless special case like TabBar or login).

Check bottom navigation (currentIndex set correctly, -1 for non-nav screens).

Run flutter analyze after each package.

Document updated vs. Scaffold-kept screens.

Here’s a clean list of all Packages and their Screens that appear in your tree output:

artbeat_admin
admin_ad_management_screen.dart


admin_advanced_content_management_screen.dart


admin_advanced_user_management_screen.dart


admin_analytics_screen.dart


admin_content_review_screen.dart


admin_dashboard_screen.dart


admin_data_management_screen.dart


admin_enhanced_dashboard_screen.dart


admin_financial_analytics_screen.dart


admin_help_support_screen.dart


admin_login_screen.dart


admin_security_center_screen.dart


admin_settings_screen.dart


admin_system_alerts_screen.dart


admin_user_detail_screen.dart


admin_user_management_screen.dart



artbeat_ads
ad_payment_screen.dart


simple_ad_create_screen.dart


simple_ad_management_screen.dart


simple_ad_statistics_screen.dart



artbeat_art_walk
art_walk_dashboard_screen.dart


art_walk_detail_screen.dart


art_walk_edit_screen.dart


art_walk_experience_screen.dart


art_walk_list_screen.dart


art_walk_map_screen.dart


create_art_walk_screen.dart


enhanced_art_walk_create_screen.dart


enhanced_art_walk_experience_screen.dart


my_captures_screen.dart



artbeat_artist
analytics_dashboard_screen.dart


artist_approved_ads_screen.dart


artist_browse_screen.dart


artist_dashboard_screen.dart


artist_journey_screen.dart


artist_list_screen.dart


artist_onboarding_screen.dart


artist_profile_edit_screen.dart


artist_public_profile_screen.dart


artwork_browse_screen.dart


commissions/commission_details_sheet.dart


commissions/commissions_screen.dart


event_creation_screen.dart


events_screen.dart


featured_artist_screen.dart


gallery_analytics_dashboard_screen.dart


gallery_artists_management_screen.dart


modern_2025_onboarding_screen.dart


my_artwork_screen.dart


payment_methods_screen.dart


payment_screen.dart


refund_request_screen.dart


subscription_analytics_screen.dart


verified_artist_screen.dart



artbeat_artwork
artwork_browse_screen.dart


artwork_detail_screen.dart


artwork_edit_screen.dart


artwork_upload_screen.dart


enhanced_artwork_upload_screen.dart



artbeat_auth
forgot_password_screen.dart


login_screen.dart


register_screen.dart



artbeat_capture
admin_content_moderation_screen.dart


camera_capture_screen.dart


camera_only_screen.dart


capture_confirmation_screen.dart


capture_detail_screen.dart


capture_details_screen.dart


capture_upload_screen.dart


captures_list_screen.dart


enhanced_capture_dashboard_screen.dart


terms_and_conditions_screen.dart



artbeat_community
commissions/commissions_screen.dart


feed/artist_community_feed_screen.dart


feed/comments_screen.dart


feed/create_group_post_screen.dart


feed/create_post_screen.dart


feed/trending_content_screen.dart


feed/unified_community_feed.dart


gifts/gift_rules_screen.dart


gifts/gifts_screen.dart


home/canvas_feed_screen.dart


moderation/moderation_queue_screen.dart


portfolios/artist_portfolio_screen.dart


portfolios/portfolios_screen.dart


posts/user_posts_screen.dart


search/post_search_screen.dart


search/user_search_screen.dart


settings/quiet_mode_screen.dart


sponsorships/sponsorship_screen.dart


studios/studio_chat_screen.dart


studios/studios_screen.dart


src/screens/community_artists_screen.dart


src/screens/community_dashboard_screen.dart


src/screens/community_feed_screen.dart



artbeat_core
auth_required_screen.dart


fluid_dashboard_screen.dart


fluid_dashboard_screen_refactored.dart


gift_purchase_screen.dart


migrate_dashboard.dart


payment_management_screen.dart


search_results_screen.dart


simple_subscription_plans_screen.dart


splash_screen.dart


subscription_plans_screen.dart


subscription_purchase_screen.dart


system_settings_screen.dart



artbeat_events
create_event_screen.dart


event_details_screen.dart


event_details_wrapper.dart


events_dashboard_screen.dart


events_list_screen.dart


my_tickets_screen.dart


user_events_dashboard_screen.dart



artbeat_messaging
artistic_messaging_screen.dart


blocked_users_screen.dart


chat_info_screen.dart


chat_list_screen.dart


chat_notification_settings_screen.dart


chat_screen.dart


chat_search_screen.dart


chat_settings_screen.dart


chat_wallpaper_selection_screen.dart


contact_selection_screen.dart


enhanced_messaging_dashboard_screen.dart


group_chat_screen.dart


group_creation_screen.dart


group_edit_screen.dart


media_viewer_screen.dart


messaging_dashboard_screen.dart


user_profile_screen.dart



artbeat_profile
achievement_info_screen.dart


achievements_screen.dart


create_profile_screen.dart


discover_screen.dart


edit_profile_screen.dart


favorite_detail_screen.dart


favorites_screen.dart


followers_list_screen.dart


following_list_screen.dart


profile_picture_viewer_screen.dart


profile_tab.dart


profile_view_screen.dart


user_favorites_screen.dart



artbeat_settings
account_settings_screen.dart


become_artist_screen.dart


blocked_users_screen.dart


notification_settings_screen.dart


privacy_settings_screen.dart


security_settings_screen.dart


settings_screen.dart
