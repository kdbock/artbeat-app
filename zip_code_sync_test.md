# ZIP Code Synchronization Test

## Test the fixes for ZIP code synchronization across Google Maps screens

### Before Testing:
1. Make sure the app builds successfully
2. Clear user data or test with a fresh account
3. Enable location services on device/emulator

### Test Cases:

#### Test 1: Dashboard Screen ZIP Code Sync
1. Open the app and navigate to Dashboard
2. Check console logs for "📍 Dashboard: Using user ZIP code:" or "📍 Dashboard: Updated user ZIP code to:"
3. Verify the map centers on the correct location
4. Expected: User's ZIP code should be saved and used for location

#### Test 2: Art Walk Map Screen ZIP Code Integration
1. Navigate to Art Walk Map Screen
2. Check console logs for "📍 Loaded user ZIP code:" 
3. Try searching for a different ZIP code
4. Check if it updates the user's profile
5. Expected: Should show user's ZIP code by default, not "00000"

#### Test 3: Art Walk Dashboard ZIP Code Usage
1. Navigate to Art Walk Dashboard
2. Check console logs for "📍 Art Walk Dashboard: Loaded user ZIP code:"
3. Verify the "Discover" tab shows relevant local walks
4. Expected: Should load walks relevant to user's location

#### Test 4: Cross-Screen Synchronization
1. Update ZIP code in one screen (e.g., by searching in Art Walk Map)
2. Navigate to other screens
3. Verify all screens now use the updated ZIP code
4. Expected: All screens should be synchronized

### Console Log Patterns to Watch:
- `📍 Loaded user ZIP code: [ZIPCODE]`
- `✅ Successfully updated user ZIP code to: [ZIPCODE]`
- `📍 Using user profile ZIP code: [ZIPCODE]`
- `📍 Location-derived ZIP code: [ZIPCODE]`

### Success Criteria:
- [ ] No more "00000" ZIP codes appearing
- [ ] User's ZIP code persists across app sessions
- [ ] All three map screens show the same location
- [ ] Searching for ZIP codes updates user profile
- [ ] Relevant local content appears in all screens