/// Account-based Seal access control for TaskForm.
/// Only the form creator (by address) can decrypt sensitive submissions.
///
/// Key format: [pkg id][bcs::to_bytes(creator_address)]
/// - Encrypt: use creator address as identity
/// - Decrypt: only creator address can call seal_approve
///
module taskform::seal_policy;

use sui::bcs;

const ENoAccess: u64 = 100;

entry fun seal_approve(id: vector<u8>, ctx: &TxContext) {
  let caller_bytes = bcs::to_bytes(&ctx.sender());
  assert!(id == caller_bytes, ENoAccess);
}
