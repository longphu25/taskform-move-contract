#[allow(unused_const)]
module taskform::submission;

use sui::dynamic_field;

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
/// Stored as dynamic field on Form object.
public struct SubmissionMeta has store {
  id: ID,
  form_id: ID,
  submitter: address,
  submission_blob_id: vector<u8>,
  submission_blob_object_id: ID,
  submission_download_id: vector<u8>,
  expiry_epoch: u64,
  created_at_ms: u64,
  status: u8,
  priority: u8,
}

// === Public Accessors ===

public fun id(sub: &SubmissionMeta): ID {
  sub.id
}

public fun form_id(sub: &SubmissionMeta): ID {
  sub.form_id
}

public fun submitter(sub: &SubmissionMeta): address {
  sub.submitter
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
  submitter: address,
  submission_blob_id: vector<u8>,
  submission_blob_object_id: ID,
  submission_download_id: vector<u8>,
  expiry_epoch: u64,
  created_at_ms: u64,
  ctx: &mut TxContext,
): SubmissionMeta {
  let uid = object::new(ctx);
  let id = object::uid_to_inner(&uid);
  object::delete(uid);
  SubmissionMeta {
    id,
    form_id,
    submitter,
    submission_blob_id,
    submission_blob_object_id,
    submission_download_id,
    expiry_epoch,
    created_at_ms,
    status: STATUS_NEW,
    priority: PRIORITY_LOW,
  }
}

/// Store submission as dynamic field on form
public(package) fun add_to_form(form_uid: &mut UID, sub: SubmissionMeta) {
  let sub_id = sub.id;
  dynamic_field::add(form_uid, sub_id, sub);
}

/// Borrow mutable submission from form
public(package) fun borrow_mut(form_uid: &mut UID, submission_id: ID): &mut SubmissionMeta {
  dynamic_field::borrow_mut(form_uid, submission_id)
}

public(package) fun set_status(sub: &mut SubmissionMeta, new_status: u8) {
  sub.status = new_status;
}

public(package) fun set_priority(sub: &mut SubmissionMeta, new_priority: u8) {
  sub.priority = new_priority;
}
