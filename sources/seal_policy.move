/// Seal access control for TaskForm.
/// Only the form creator (holder of CreatorCap) can decrypt sensitive submissions.
///
/// Key format: [pkg id][form object id][nonce]
/// - Encrypt: anyone can encrypt using form's object ID as identity prefix
/// - Decrypt: only CreatorCap holder for that form can call seal_approve
///
module taskform::seal_policy;

use taskform::capabilities::CreatorCap;

const ENoAccess: u64 = 100;

/// Verify caller holds CreatorCap for the form matching the encrypted ID prefix.
/// Key servers call this to validate decryption requests.
entry fun seal_approve(id: vector<u8>, cap: &CreatorCap) {
  let form_id_bytes = object::id_from_bytes(cap.form_id().to_bytes()).to_bytes();
  // id must start with form_id bytes
  let mut i = 0;
  assert!(form_id_bytes.length() <= id.length(), ENoAccess);
  while (i < form_id_bytes.length()) {
    assert!(form_id_bytes[i] == id[i], ENoAccess);
    i = i + 1;
  };
}
