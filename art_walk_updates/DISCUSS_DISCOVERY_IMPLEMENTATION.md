# Discuss Discovery Button Implementation

## Overview

Added a "Discuss Discovery" button to the discovery capture modal that allows users to create community posts about discovered art, enabling them to fulfill discovery-related quests (like "discuss 3 discoveries").

## Feature Flow

1. **User discovers art** on the radar and taps to view capture details
2. **User taps "Capture Discovery"** button
   - Art is captured and XP is awarded (+20 XP)
   - Confetti animation plays
   - Success message displays
3. **"Discuss Discovery" button appears** alongside the success message
4. **User taps "Discuss Discovery"**
   - Modal closes smoothly
   - Navigates to CreatePostScreen with pre-filled data:
     - Art image from the discovery
     - Pre-filled caption: "📍 Discussing '[Art Title]' by [Artist]\n\n"
     - User can add their own comment/discussion
5. **User posts the discussion**
   - Community post is created with the art image and discussion text
   - Post appears in the Community Hub feed
   - User is redirected back to the discovery screen

## Files Modified

### 1. `/packages/artbeat_community/lib/screens/feed/create_post_screen.dart`

**Changes:**

- Added optional constructor parameters:
  - `prefilledImageUrl`: URL of the art image from discovery
  - `prefilledCaption`: Pre-filled caption with art details
  - `isDiscussionPost`: Flag indicating this is a discovery discussion
- Added state variable `_prefilledImageUrl` to store the image URL

- Added `_loadPrefilledImage()` method to initialize pre-filled data on screen load

- Modified `initState()` to:

  - Load pre-filled caption text into the content controller
  - Call `_loadPrefilledImage()`

- Updated `_buildMediaPreview()` to display pre-filled image preview with "Discovery" badge

- Added `_buildPrefilledImagePreview()` widget to show discovery image with badge

- Modified `_createPost()` to include the pre-filled image URL in the final post:

  - Pre-filled image is added as the first image in the post
  - Additional user-selected images can be included alongside it

- Added import: `package:cached_network_image/cached_network_image.dart`

### 2. `/packages/artbeat_art_walk/lib/src/widgets/discovery_capture_modal.dart`

**Changes:**

- Added import: `package:artbeat_community/screens/feed/create_post_screen.dart`

- Modified success message UI (lines 362-384):

  - Changed from simple container to a Column containing:
    - Success message container
    - New "Discuss Discovery" button below it

- Added `_navigateToDiscussPost()` method that:

  - Builds a pre-filled caption with emoji and art details
  - Closes the modal gracefully
  - Waits for modal to close
  - Navigates to CreatePostScreen with:
    - Art image URL
    - Pre-filled caption
    - Discovery discussion flag

- Updated UI to show "Discuss Discovery" button with comment icon

### 3. `/packages/artbeat_art_walk/pubspec.yaml`

**Changes:**

- Added dependency: `artbeat_community: path: ../artbeat_community`

This allows cross-package navigation from art_walk to community features.

## User Experience

### Success Flow

1. User successfully captures a discovery
2. Sees green success message and confetti
3. Sees "Discuss Discovery" button become available
4. Taps the button and is taken to post creation screen
5. Sees art image pre-loaded in the discussion post
6. Can add their comment and post to the community hub
7. Returns to the discovery screen after posting

### Technical Details

**Pre-filled Caption Format:**

```
📍 Discussing "[Art Title]" by [Artist]

[User's discussion text here]
```

**Image Handling:**

- Pre-filled image is displayed with a visual "Discovery" badge
- Pre-filled image is automatically included in the post
- Users can add additional images if desired

**Navigation:**

- Modal properly closes before navigation
- User returns to discovery screen when post is complete
- No lost context or navigation issues

## Quest Integration

This feature fulfills discovery-related quests such as:

- "Discuss 3 discoveries"
- "Share your discoveries with the community"

The posts created through this feature are tagged as discovery discussions through:

- Pre-filled caption mentioning the art title and artist
- Optional `isDiscussionPost` flag for future quest tracking
- Post metadata that can include discovery information

## Testing Recommendations

1. **Basic Flow:**

   - Tap on discovered art
   - Capture the discovery
   - Verify "Discuss Discovery" button appears
   - Tap button and verify navigation to post creation

2. **Pre-filled Data:**

   - Verify art image displays with "Discovery" badge
   - Verify caption text is pre-filled correctly
   - Verify user can add additional text

3. **Post Creation:**

   - Create a post with pre-filled data
   - Verify post appears in community hub with correct image
   - Verify user is returned to discovery screen

4. **Edge Cases:**
   - Verify behavior if image URL is invalid
   - Verify behavior if user cancels post creation
   - Verify multiple discussions of the same art

## Future Enhancements

Possible improvements for future iterations:

1. Add tags like `#discovery` or `#artwalk` automatically
2. Include location data in the post metadata
3. Create a link back to the original discovery
4. Add special badge/icon for discovery discussions in the feed
5. Track discovery discussion quest progress
6. Show discussion count on the discovery radar item
