#[allow(unused_const, lint(custom_state_change))]
module taskform::submission;

// === Constants ===

const STATUS_NEW: u8 = 0;
const STATUS_REVIEWING: u8 = 1;
const STATUS_PLANNED: u8 = 2;
const STATUS_IN_PROGRESS: u8 = 3;
const STATUS_DONE: u8 = 4;
const STATUS_ARCHIVED: u8 = 5;

const PRIORITY_LOW: u8 = 0;
const PRIORITY_MEDIUM: u8 = 1;
const PRIORITY_HIGH: u8 = 2;
const PRIORITY_CRITICAL: u8 = 3;

// === Struct ===

/// Metadata pointer for a submission stored on Walrus.
public struct SubmissionMeta has key, store {
  id: UID,
  form_id: ID,
  submission_blob_id: vector<u8>,
  submission_blob_object_id: ID,
  expiry_epoch: u64,
  created_at_ms: u64,
  status: u8,
  priority: u8,
}

// === Public Accessors ===

public fun id(sub: &SubmissionMeta): ID {
  object::uid_to_inner(&sub.id)
}

public fun form_id(sub: &SubmissionMeta): ID {
  sub.form_id
}

public fun status(sub: &SubmissionMeta): u8 {
  sub.status
}

public fun priority(sub: &SubmissionMeta): u8 {
  sub.priority
}

public fun submission_blob_id(sub: &SubmissionMeta): vector<u8> {
  sub.submission_blob_id
}

// === Validation ===

public fun is_valid_status(status: u8): bool {
  status <= STATUS_ARCHIVED
}

public fun is_valid_priority(priority: u8): bool {
  priority <= PRIORITY_CRITICAL
}

// === Package-Internal Functions ===

public(package) fun new(
  form_id: ID,
  submission_blob_id: vector<u8>,
  submission_blob_object_id: ID,
  expiry_epoch: u64,
  created_at_ms: u64,
  ctx: &mut TxContext,
): SubmissionMeta {
  SubmissionMeta {
    id: object::new(ctx),
    form_id,
    submission_blob_id,
    submission_blob_object_id,
    expiry_epoch,
    created_at_ms,
    status: STATUS_NEW,
    priority: PRIORITY_LOW,
  }
}

public(package) fun set_status(sub: &mut SubmissionMeta, new_status: u8) {
  sub.status = new_status;
}

public(package) fun set_priority(sub: &mut SubmissionMeta, new_priority: u8) {
  sub.priority = new_priority;
}

public(package) fun transfer_to_sender(sub: SubmissionMeta, sender: address) {
  transfer::transfer(sub, sender);
}
