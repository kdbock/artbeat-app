# ArtBeat Auth - User Experience Guide

This document outlines the complete user experience flow for the ArtBeat authentication system, detailing every step a user encounters from initial app launch through successful authentication.

## 📱 Authentication Flow Overview

```
App Launch → Auth Check → Route Decision → Authentication → Profile Setup → Dashboard
```

## 🚀 User Journey Flows

### 1. New User Registration Flow

#### **Entry Point**: First-time app launch or "Sign Up" from login

**Step 1: Registration Screen**

- **Screen**: `RegisterScreen`
- **User Sees**:
  - ArtBeat branded header with teal background (#46a8c3)
  - "Create Account" title
  - Form fields:
    - First Name (required)
    - Last Name (required)
    - Email Address (required, validated)
    - Password (required, with visibility toggle)
    - Confirm Password (required, real-time matching)
  - Terms of Service checkbox (required)
  - "Create Account" button
  - "Already have an account? Sign In" link

**User Actions**:

- Fills out all required fields
- Agrees to terms of service
- Taps "Create Account"

**Validation Feedback**:

- Real-time email format validation
- Password confirmation matching
- Required field indicators
- Error messages display below invalid fields

**Success Path**: → Email Verification Screen
**Error Path**: → Display error message, stay on registration

---

**Step 2: Email Verification Screen**

- **Screen**: `EmailVerificationScreen`
- **User Sees**:
  - "Verify Your Email" title
  - Message: "We've sent a verification link to [email]"
  - "Check your email and click the verification link"
  - "Resend Email" button (with cooldown timer)
  - Automatic checking indicator
  - "Back to Login" option

**User Actions**:

- Checks email inbox
- Clicks verification link in email
- Returns to app (auto-detected)

**System Behavior**:

- Automatically checks verification status every 3 seconds
- Shows countdown timer for resend (60 seconds)
- Auto-navigates when verification detected

**Success Path**: → Profile Creation Screen
**Error Path**: → Shows resend options, troubleshooting tips

---

**Step 3: Profile Creation**

- **Screen**: `ProfileCreateScreen` (bridges to `artbeat_profile`)
- **User Experience**: Comprehensive profile setup with photo, bio, location preferences
- **Success Path**: → Dashboard

---

### 2. Returning User Login Flow

#### **Entry Point**: App launch with no saved session

**Step 1: Login Screen**

- **Screen**: `LoginScreen`
- **User Sees**:
  - ArtBeat logo and branded header
  - "Welcome Back" message
  - Email/password form fields
  - "Sign In" button
  - Social authentication options:
    - "Continue with Google" button
    - "Continue with Apple" button (iOS only)
  - "Forgot Password?" link
  - "Don't have an account? Sign Up" link

**User Actions - Email/Password**:

- Enters email and password
- Taps "Sign In"

**User Actions - Social Authentication**:

- Taps Google/Apple button
- Completes platform-specific auth flow
- Returns to app with credentials

**Success Paths**:

- Email verified + Profile exists → Dashboard
- Email verified + No profile → Profile Creation
- Email not verified → Email Verification Screen

**Error Path**: → Display error message, remain on login

---

### 3. Password Recovery Flow

#### **Entry Point**: "Forgot Password?" from login screen

**Step 1: Forgot Password Screen**

- **Screen**: `ForgotPasswordScreen`
- **User Sees**:
  - "Reset Password" title
  - Instructions: "Enter your email to receive reset instructions"
  - Email input field
  - "Send Reset Email" button
  - "Back to Login" link

**User Actions**:

- Enters email address
- Taps "Send Reset Email"

**Success Experience**:

- Shows confirmation: "Reset email sent to [email]"
- Instructions to check email
- Auto-redirect to login after delay

**Error Experience**:

- Shows error if email not found
- Suggests checking spelling or signing up

---

### 4. Social Authentication Flow

#### **Google Sign-In Experience**

**User Journey**:

1. Taps "Continue with Google" on login screen
2. Google sign-in modal appears
3. User selects Google account or enters credentials
4. Grants permissions to ArtBeat
5. Returns to app

**First-Time Social User**:

- Auto-creates user document in Firestore
- Uses Google display name and email
- Directs to profile completion (for additional details)

**Returning Social User**:

- Immediate login
- Directs to dashboard

#### **Apple Sign-In Experience** (iOS only)

**User Journey**:

1. Taps "Continue with Apple" on login screen
2. Apple Sign-In modal with Face ID/Touch ID
3. User authenticates with biometrics or passcode
4. Chooses to share or hide email
5. Returns to app

**Security Features**:

- Cryptographic nonce generation
- Secure credential exchange
- Privacy-focused email options

---

### 5. Email Verification Experience

#### **Verification Required States**

**Automatic Checking**:

- Screen checks verification status every 3 seconds
- Shows subtle loading indicator
- No user action required if they verify in email

**Manual Resend**:

- "Resend Email" button available
- 60-second cooldown prevents spam
- Confirmation message when resent
- Updated instruction text

**Troubleshooting Options**:

- "Check spam folder" reminder
- "Try different email" option
- Contact support information

---

## 🎨 Visual Design Elements

### Color Scheme

- **Primary Header**: `#46a8c3` (Teal blue)
- **Accent/Text**: `#00bf63` (Green)
- **Background**: White/Light gray
- **Error States**: Standard red
- **Success States**: Green accent

### Typography

- **Headers**: Limelight font family
- **Body Text**: System default
- **Button Text**: Bold system font

### Interactive Elements

- **Buttons**:
  - Primary: Filled with accent color
  - Secondary: Outlined
  - Social: Platform-branded colors
- **Form Fields**:
  - Clean borders
  - Focus states with accent color
  - Error states with red borders
- **Loading States**:
  - Circular progress indicators
  - Disabled button states

---

## 📊 User Experience Metrics

### Success Criteria

- **Registration Completion**: User creates account and verifies email
- **Login Success Rate**: Successful authentication without errors
- **Social Auth Adoption**: Usage of Google/Apple sign-in options
- **Email Verification Time**: Time from registration to verification
- **Password Reset Success**: Successful password recovery completion

### Error Recovery

- **Clear Error Messages**: Specific, actionable error descriptions
- **Retry Mechanisms**: Easy retry for failed operations
- **Alternative Paths**: Multiple authentication options available
- **Help Resources**: Links to support and troubleshooting

### Accessibility Features

- **Screen Reader Support**: Semantic labels and descriptions
- **Keyboard Navigation**: Full keyboard accessibility
- **High Contrast**: Readable color combinations
- **Font Scaling**: Respect system font size preferences

---

## 🔄 State Management

### Loading States

- **Button Loading**: Spinner replaces button text during operations
- **Screen Loading**: Full-screen indicators for navigation
- **Background Loading**: Subtle indicators for auto-checking

### Error States

- **Validation Errors**: Real-time field-level feedback
- **Network Errors**: Retry options and offline indicators
- **Authentication Errors**: Clear explanation and next steps
- **System Errors**: Graceful fallbacks and error reporting

### Success States

- **Confirmation Messages**: Clear success indicators
- **Auto Navigation**: Smooth transitions between screens
- **Progress Indicators**: Show user progress through flow

---

## 🧪 Testing Scenarios

### Happy Path Testing

1. **Complete Registration**: New user → Register → Verify → Profile → Dashboard
2. **Returning Login**: Existing user → Login → Dashboard
3. **Social Authentication**: User → Google/Apple → Dashboard
4. **Password Recovery**: User → Forgot Password → Email → Reset → Login

### Edge Case Testing

1. **Network Interruption**: Handle connectivity issues gracefully
2. **Email Verification Delay**: Extended verification checking
3. **Multiple Devices**: Same user logging in from different devices
4. **Account State Conflicts**: Handle edge cases in user document creation

### Error Scenario Testing

1. **Invalid Credentials**: Clear error messaging and recovery
2. **Email Already Exists**: Appropriate handling and user guidance
3. **Social Auth Cancellation**: Graceful handling of user cancellation
4. **Email Service Issues**: Fallback options for email delivery problems

---

## 📱 Platform-Specific Considerations

### iOS Specific

- **Apple Sign-In**: Native iOS integration with Face ID/Touch ID
- **Keychain Integration**: Secure credential storage
- **App Store Guidelines**: Privacy-compliant data handling

### Android Specific

- **Google Sign-In**: Native Android integration
- **Biometric Authentication**: Fingerprint and face unlock support
- **Play Store Guidelines**: Security and privacy compliance

### Web Specific

- **Browser Compatibility**: Cross-browser authentication support
- **Social Auth Limitations**: Platform-specific restrictions
- **PWA Features**: Progressive web app authentication flows

---

This user experience guide ensures consistent, intuitive authentication flows that prioritize user security, accessibility, and ease of use across all platforms and scenarios.
