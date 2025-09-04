const { execSync } = require('child_process');

async function setUserAsAdmin(email) {
  try {
    if (!email) {
      console.error('❌ Please provide an email address');
      console.log('Usage: node set_admin_user_cli.js <email>');
      process.exit(1);
    }

    console.log(`🔍 Setting up admin privileges for: ${email}`);
    
    // Use Firebase CLI to run a Firestore query and update
    const updateCommand = `firebase firestore:update users --where "email==${email}" --data '{"userType":"admin","updatedAt":"{{serverTimestamp}}"}'`;
    
    console.log('📝 Running Firebase CLI command...');
    console.log('Note: This requires Firebase CLI to be logged in and configured');
    
    try {
      execSync(updateCommand, { stdio: 'inherit' });
      console.log('✅ Successfully set user as admin!');
      console.log(`🔑 ${email} now has admin privileges`);
    } catch (error) {
      console.log('⚠️  Firebase CLI command failed. Let\'s try a manual approach...');
      console.log('');
      console.log('📋 Manual steps to set admin privileges:');
      console.log('1. Go to Firebase Console: https://console.firebase.google.com/project/wordnerd-artbeat/firestore');
      console.log('2. Navigate to the "users" collection');
      console.log(`3. Find the document with email: ${email}`);
      console.log('4. Edit the document and set the "userType" field to "admin"');
      console.log('5. Save the changes');
      console.log('');
      console.log('🔄 After making these changes, restart your app to see the admin features.');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Get email from command line arguments
const email = process.argv[2];
setUserAsAdmin(email);