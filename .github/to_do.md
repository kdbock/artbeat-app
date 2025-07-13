the loading your art experience popup upon loading is not working properly.
Art_walk_dashboard_screen has duplicated bottom navigation, MainLayout. 
attempted to use search bar in header, searched for Kelly, an artist in the database last name search results for Kelly were not there. 
Discover and connect icon items need routing checked, they reload app instead of connecting to their screen.
developer icon admin Panel needs routing checked, it reloads app instead of connecting to its screen.
developer icon item system needs ontap checked, and routing checked. nothing happens when tapped. 
fluid_dashboard_screen - art around you section - create art walk buttion needs routing checked, it reloads app instead of connecting to its screen.
fluid_dashboard_screen - art around you section - map needs ontap checked, and routing checked. nothing happens when tapped. It should go to map screen with markers on it and current and user art walks displayed. 
fluid_dashboard_screen - Quick Actions Section - Start Art Walk should route directly to the create_art_walk_screen.
fluid_dashboard_screen - Quick Actions Section - My Art Walks should route directly to the my_art_walking_screen.
fluid_dashboard_screen - Quick Actions Section - change black background behind circle icons to a very light blue. Check routing and screen connection as when tapped app reloads. 
fluid_dashboard_screen - Featured Artists section - View All buttion needs routing checked, it reloads app instead of connecting to its screen.
fluid_dashboard_screen - Featured Artists section - no artists are showing despite artistProfile connection having isFeatured: true in profiles in database. 
fluid_dashboard_screen - Community Highlights section - no posts are showing despite having posts in database.
fluid_dashboard_screen - Artwork Gallery section - no artwork is showing despite artwork collection in database.
fluid_dashboard_screen - Are you an artist section - Artist benefit button does not link to a benefit screen. Check routing for Join as Artist buttion does not connect to screen reloads app.

Check capture process routing and function:
enchanced_capture_dashboard_screen - after user taps on Capture button, they are presented with terms and conditions to accept before proceeding.
Capture process - after user accepts conditions, the camera opens up and allows them to take a picture.
capture_process_screen - after user takes photo, they are presented with options to save or discard image.
capture_process_screen - if user chooses to save image, they are taken to the capture_details_screen where they can add details about their capture.
capture_process_screen - if user chooses to discard image, they are returned back to take another picture.
capture_details_screen - after user adds details about their capture, they are taken to the capture_confirmation_screen where they can confirm their capture details before saving them to the database. This also explains that admin will review their capture before it is published.
capture_confirmation_screen - if user rejects their capture details, they are taken to the capture_details_screen where they can edit their capture details.
capture_confirmation_screen - if user confirms their capture details, they are taken to the fluid_dashboard_screen where they can see their capture listed under "My Captures" with a pending status.
capture_confirmation_screen - if user cancels confirmation, they are returned back to the capture_details_screen where they can edit their capture details.
admin_content_moderation - user captures are reviewed by admin and either approved or rejected. If approved, the capture is published to the capture feeds. If rejected, the capture is deleted from the database. Status is updated on user my captures screen.
admin_content_moderation - admin can delete any capture from the database at anytime.
approved captures are used for art_walk creations by location. They load as locations on the map for all users to use. 
