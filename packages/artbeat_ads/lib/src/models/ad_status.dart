/// Status of an ad in the system
enum AdStatus {
  pending, // Awaiting approval
  approved, // Approved and scheduled
  rejected, // Rejected by admin
  running, // Currently running
  expired, // Finished
}
