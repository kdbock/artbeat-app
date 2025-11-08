# Apple App Store Review Response - Report/Block Mechanism

## Where can users locate the precautions for user-generated content? (Report/Block mechanism)

### **🛡️ Report/Block Features are Available in Multiple Locations:**

#### **1. Community Feed Posts** ✅

- **Location**: Main community feed screen (`art_community_hub.dart`)
- **How to access**:
  1. Browse the community feed
  2. Tap the **three-dot menu (⋮)** in the top-right corner of any post
  3. Select **"Report"** → Choose from 7 report categories → Submit
  4. Select **"Block user"** → Confirm to block the content creator
- **Implementation**: `EnhancedPostCard` widget with integrated `UserActionMenu`

#### **2. User Profiles & Comments**

- **Location**: Artist profiles and comment sections
- **How to access**:
  1. Visit any user's profile or view comments
  2. Tap the **profile menu** or **comment menu**
  3. Select **"Report"** to report a user or specific comment
  4. Select **"Block user"** to prevent seeing content from that user

#### **3. Blocked Users Management**

- **Location**: Settings → Privacy Settings → Blocked Users
- **Features**:
  - View complete list of blocked users
  - Unblock users as needed
  - Manage privacy preferences

### **🔍 Report Categories Available:**

1. Harassment or bullying
2. Hate speech or discrimination
3. Inappropriate content
4. Spam or scam
5. Copyright infringement
6. Misinformation
7. Other (with custom description)

### **⚡ How It Works:**

- All reports are submitted to our moderation team for review
- Blocked users cannot view your profile or interact with your content
- Users receive confirmation when reports are successfully submitted
- Reports include timestamp, user ID, and detailed reason for review

### **📍 Integration Status:**

- Community feed posts ✅ **FULLY IMPLEMENTED** (Three-dot menu with Report & Block user)
- Artist profiles ❓ **NEEDS VERIFICATION**
- User comments ❓ **NEEDS VERIFICATION**
- Gallery content ❓ **NEEDS VERIFICATION**
- Event listings ❓ **NEEDS VERIFICATION**

### **� IMPLEMENTED FIX:**

Added `UserActionMenu` three-dot menu to post headers in the main community feed. Users can now access both Report and Block user functionality from the three-dot menu (⋮) on each post.

**Technical Implementation**: The system uses Firebase Firestore to store reports in a `/reports` collection and blocked users in `/users/{userId}/blockedUsers` subcollections, ensuring secure and scalable moderation.
