# Commission Wizard - Quick Testing Guide ⚡

**Duration**: ~15-20 minutes to test all flows

---

## 🎬 Test Scenarios

### Scenario 1: First-Time Artist Setup (Main Flow)

**What to Test**: New artist with no commission settings

**Steps**:

1. **Open CommissionHubScreen**

   - Log in as any user who hasn't set up artist commissions
   - Navigate to Commissions tab

2. **Verify UI**

   - ✅ Should see "Artist Dashboard" section
   - ✅ Should show "Complete your commission setup" warning box
   - ✅ Should see "Quick Setup Wizard" (purple button - PRIMARY)
   - ✅ Should see "Detailed Settings" (outlined button - secondary)

3. **Click "Quick Setup Wizard"**

   - ✅ Header shows "Set Up Commissions (Step 1/6)"
   - ✅ Page shows welcome screen with:
     - Art track icon
     - "Start Accepting Commissions" heading
     - List of what will be set up
     - "Accept Commissions" toggle
     - Next button

4. **Complete Step 1 (Welcome)**

   - Toggle "Accept Commissions" on/off (default: on)
   - Click "Next" → Advance to Step 2

5. **Complete Step 2 (Commission Types)**

   - ✅ Header shows "Step 2/6"
   - Should see checkboxes for:
     - Digital
     - Physical
     - Portrait
     - Commercial
   - Select at least 2 types
   - Click "Next"

6. **Complete Step 3 (Basic Pricing)**

   - ✅ Header shows "Step 3/6"
   - Set Base Price: use slider, change value
   - ✅ Display shows: "$X.XX" in green
   - Set Turnaround Time: use slider, change value
   - ✅ Display shows: "X days" in blue
   - Click "Next"

7. **Complete Step 4 (Portfolio Images)** ⭐ NEW

   - ✅ Header shows "Step 4/6"
   - Heading: "Build Your Portfolio"
   - Should show empty state: "No portfolio images added"
   - Click "Add Portfolio Image"
     - ✅ Dialog appears: "Select Image Source"
     - Select "Gallery" (or Camera if device available)
     - Pick an image from device
     - ✅ See loading: "Uploading..."
     - ✅ Success message: "✅ Portfolio image uploaded successfully!"
     - ✅ Image appears in 3-column grid
   - Add 2-3 more images
   - ✅ Click X on an image → verify removal
   - Click "Next"

8. **Complete Step 5 (Advanced Pricing)** ⭐ NEW

   - ✅ Header shows "Step 5/6"
   - **Commission Type Modifiers section**:
     - For each selected type, should see slider
     - Set modifiers (e.g., Digital: $0, Physical: +$50)
     - ✅ Values display in green
   - **Size Modifiers section**:
     - 5 size options (Small, Medium, Large, Extra Large, Custom)
     - Adjust sliders (e.g., Small: $0, Large: +$100)
   - **Max Active Commissions**:
     - Slider from 1-20
     - Set to 10
     - ✅ Display shows: "10 commissions max"
   - **Deposit Required**:
     - Slider from 25-100%
     - Set to 50%
     - ✅ Display shows: "50% of total price"
   - Click "Next"

9. **Complete Step 6 (Review)** ⭐ ENHANCED

   - ✅ Header shows "Step 6/6"
   - Review section shows colored cards:
     - Accepting Commissions: ✅ Yes (or ⏸ No)
     - Commission Types: (list selected)
     - Base Price: $X.XX (green)
     - Turnaround Time: X days (orange)
     - **Portfolio section**: X images (indigo)
     - **Pricing Details**:
       - Max Active Commissions: X (teal)
       - Deposit Required: X% (pink)
   - Green success box: "You're all set! 🎉"
   - Click "Save & Finish"
     - ✅ Success message: "✅ Commission settings saved successfully!"
     - Should navigate back to hub
     - ✅ Hub refreshes and shows artist section with new settings

10. **Verify Hub Updated**
    - ✅ Should now show "Currently accepting commissions" ✅
    - ✅ Shows "Base Price: $X.XX"
    - ✅ Shows "Available Types: ..."
    - ✅ Two buttons: "Edit (Wizard)" and "Advanced"

---

### Scenario 2: Edit via Wizard (Editing Mode)

**What to Test**: Artist with existing settings can edit via wizard

**Prerequisites**: Complete Scenario 1 first

**Steps**:

1. **Open CommissionHubScreen** (same artist)

   - Should already show artist section

2. **Click "Edit (Wizard)"**

   - ✅ Step 1/6 loads with wizard
   - ✅ "Accept Commissions" toggle shows CURRENT value

3. **Verify All Settings Pre-populated**

   - Step 1: Acceptance toggle matches
   - Step 2: Selected types match
   - Step 3: Base price and turnaround match
   - Step 4: Portfolio images appear
   - Step 5: All pricing modifiers match

4. **Make a Change**

   - On any step, modify a value
   - Example: Step 3, change base price to $150
   - Click "Next" through remaining steps

5. **Save Changes**
   - Click "Save & Finish"
   - ✅ Success message
   - ✅ Back to hub
   - ✅ Verify change persisted (Base Price now $150)

---

### Scenario 3: Advanced Settings Path

**What to Test**: Full settings screen still works

**Prerequisites**: Can use existing artist or create new

**Steps**:

1. **From Hub, click "Advanced"** (or "Detailed Settings" if first-time)

   - ✅ Full ArtistCommissionSettingsScreen opens
   - Should show all 11 fields in full detail

2. **Verify Features**

   - ✅ Load existing settings
   - ✅ Can edit all fields
   - ✅ Portfolio image grid works
   - ✅ Type pricing grid works
   - ✅ Size pricing grid works

3. **Make Changes & Save**
   - Change a setting
   - Click Save
   - ✅ Success message
   - ✅ Back to hub
   - ✅ Hub shows updated value

---

### Scenario 4: Back Navigation

**What to Test**: Back button works correctly

**Steps**:

1. **Open Wizard** (any step)

2. **Press back button (Android) or swipe back**

   - On Step 2: Goes to Step 1
   - On Step 1: Exits wizard
   - ✅ Does NOT exit wizard until Step 1

3. **Test "Back" button in UI**
   - While on Step 3
   - Click UI "Back" button
   - ✅ Goes to Step 2

---

### Scenario 5: Image Upload Edge Cases

**What to Test**: Image upload handles errors

**Steps**:

1. **On Step 4 (Portfolio)**

2. **Test Cancel**

   - Click "Add Portfolio Image"
   - Dialog appears
   - Press cancel/back
   - ✅ Nothing happens, stay on Step 4

3. **Test Upload Failure** (optional)

   - Requires internet disconnection or Firebase permissions issue
   - Click "Add Portfolio Image"
   - Select image
   - ✅ If fails: Error message appears
   - ✅ Can retry

4. **Test Delete**
   - Multiple images in grid
   - Click X on middle image
   - ✅ Image removed
   - ✅ Grid updates
   - Proceed to save
   - ✅ Verify deletion persisted

---

## ✅ Expected Behaviors

### UI/UX

- [ ] Header always shows "Step X/6"
- [ ] Each step has clear title and description
- [ ] Back/Next buttons work as expected
- [ ] Sliders show real-time values
- [ ] Cards show proper colors
- [ ] Success messages appear after save

### Data

- [ ] All 11 commission settings saved:
  - acceptingCommissions ✅
  - availableTypes ✅
  - basePrice ✅
  - typePricing ✅
  - sizePricing ✅
  - maxActiveCommissions ✅
  - averageTurnaroundDays ✅
  - depositPercentage ✅
  - terms ✅
  - portfolioImages ✅ (NEW)
  - lastUpdated ✅

### Navigation

- [ ] Hub → Wizard → Hub flow works
- [ ] Back button returns to hub
- [ ] Settings also accessible from hub
- [ ] Both (Wizard + Settings) reflect same data
- [ ] Refresh shows persisted data

---

## 🐛 Known Behavior (Not Bugs)

1. **Portfolio images are optional**

   - Can save wizard without images
   - Intended behavior

2. **Pricing modifiers default to 0**

   - Empty commissions initially have $0 modifiers
   - User can adjust on Step 5

3. **Back button on Step 1 exits**

   - This is expected - can't go before first step

4. **Settings refreshes on return**
   - Hub calls `_loadData()` after wizard completes
   - Small delay while data loads from Firestore
   - Expected

---

## 🚨 Issues to Report

If you encounter:

- [ ] **Cannot open wizard**: Check imports in hub
- [ ] **Settings not updating**: Check Firestore write permissions
- [ ] **Images not uploading**: Check Firebase Storage credentials
- [ ] **Back button doesn't work**: Check PopScope implementation
- [ ] **Step transitions broken**: Check PageController state

---

## 📸 Visual Checklist

### Step 1: Welcome ✅

- [ ] Art track icon visible
- [ ] Welcome text clear
- [ ] Checkboxes for "What you'll set up"
- [ ] Accept Commissions toggle
- [ ] Next button enabled

### Step 2: Types ✅

- [ ] Title: "What types of commissions..."
- [ ] 4 checkboxes (Digital, Physical, Portrait, Commercial)
- [ ] At least 1 selected required
- [ ] Back and Next buttons

### Step 3: Pricing ✅

- [ ] "Set your pricing" heading
- [ ] Base Price with large green display
- [ ] Turnaround Time with blue display
- [ ] Sliders with live updates

### Step 4: Portfolio ✅

- [ ] "Build Your Portfolio" heading
- [ ] Empty state message (if no images)
- [ ] Grid display (if has images)
- [ ] Delete X buttons
- [ ] "Add Portfolio Image" button
- [ ] Upload progress indicator

### Step 5: Advanced Pricing ✅

- [ ] "Advanced Pricing" heading
- [ ] Commission Type Modifiers (for selected types)
- [ ] Size Modifiers (5 sizes)
- [ ] Max Active Commissions slider
- [ ] Deposit Required slider
- [ ] All values display in real-time

### Step 6: Review ✅

- [ ] All previous settings shown
- [ ] Portfolio image count displayed
- [ ] Max Active and Deposit shown
- [ ] Success box: "You're all set! 🎉"
- [ ] Save button

---

## 🎯 Success Criteria

**Wizard is working correctly when**:

- ✅ New artist can complete all 6 steps
- ✅ All settings save to Firestore
- ✅ Settings appear in hub immediately after
- ✅ Existing artist can edit via wizard
- ✅ Changes persist on refresh
- ✅ Portfolio images upload and display
- ✅ Advanced settings screen still works
- ✅ Back navigation works on each step
- ✅ No errors in console
- ✅ No data loss on any transition

---

## 📋 Test Summary Template

```
Testing Date: ___________
Tester: ___________
Device: ___________

Scenario 1 (First-time): ✅ PASS / ❌ FAIL
Scenario 2 (Edit Wizard): ✅ PASS / ❌ FAIL
Scenario 3 (Advanced): ✅ PASS / ❌ FAIL
Scenario 4 (Navigation): ✅ PASS / ❌ FAIL
Scenario 5 (Images): ✅ PASS / ❌ FAIL

Overall: ✅ READY / ❌ NEEDS FIXES

Issues Found:
-
-
-

Comments:
```

---

## 🚀 Ready to Test!

All changes are in place. Start with **Scenario 1** to see the complete new flow, then move through the other scenarios.

**Expected time**: 15-20 minutes for full coverage
