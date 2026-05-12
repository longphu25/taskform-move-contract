module taskform::events;

use sui::event;

// === Event Structs ===

public struct FormCreatedEvent has copy, drop {
  form_id: ID,
  creator: address,
  schema_blob_id: vector<u8>,
  created_at_ms: u64,
}

public struct FormPublishedEvent has copy, drop {
  form_id: ID,
  creator: address,
  published_at_ms: u64,
}

public struct FormUnpublishedEvent has copy, drop {
  form_id: ID,
  creator: address,
  unpublished_at_ms: u64,
}

public struct SubmissionCreatedEvent has copy, drop {
  form_id: ID,
  submission_id: ID,
  submission_blob_id: vector<u8>,
  submitter: address,
  created_at_ms: u64,
}

public struct SubmissionUpdatedEvent has copy, drop {
  form_id: ID,
  submission_id: ID,
  status: u8,
  priority: u8,
  updated_at_ms: u64,
}

public struct AdminAddedEvent has copy, drop {
  form_id: ID,
  admin: address,
  added_at_ms: u64,
}

public struct StorageRenewedEvent has copy, drop {
  form_id: ID,
  blob_id: vector<u8>,
  new_expiry_epoch: u64,
  renewed_at_ms: u64,
}

public struct SponsoredModeUpdatedEvent has copy, drop {
  form_id: ID,
  sponsored_enabled: bool,
  updated_at_ms: u64,
}

// === Emit Functions ===

public(package) fun emit_form_created(
  form_id: ID,
  creator: address,
  schema_blob_id: vector<u8>,
  created_at_ms: u64,
) {
  event::emit(FormCreatedEvent { form_id, creator, schema_blob_id, created_at_ms });
}

public(package) fun emit_form_published(form_id: ID, creator: address, published_at_ms: u64) {
  event::emit(FormPublishedEvent { form_id, creator, published_at_ms });
}

public(package) fun emit_form_unpublished(form_id: ID, creator: address, unpublished_at_ms: u64) {
  event::emit(FormUnpublishedEvent { form_id, creator, unpublished_at_ms });
}

public(package) fun emit_submission_created(
  form_id: ID,
  submission_id: ID,
  submission_blob_id: vector<u8>,
  submitter: address,
  created_at_ms: u64,
) {
  event::emit(SubmissionCreatedEvent {
    form_id,
    submission_id,
    submission_blob_id,
    submitter,
    created_at_ms,
  });
}

public(package) fun emit_submission_updated(
  form_id: ID,
  submission_id: ID,
  status: u8,
  priority: u8,
  updated_at_ms: u64,
) {
  event::emit(SubmissionUpdatedEvent { form_id, submission_id, status, priority, updated_at_ms });
}

public(package) fun emit_admin_added(form_id: ID, admin: address, added_at_ms: u64) {
  event::emit(AdminAddedEvent { form_id, admin, added_at_ms });
}

public(package) fun emit_storage_renewed(
  form_id: ID,
  blob_id: vector<u8>,
  new_expiry_epoch: u64,
  renewed_at_ms: u64,
) {
  event::emit(StorageRenewedEvent { form_id, blob_id, new_expiry_epoch, renewed_at_ms });
}

public(package) fun emit_sponsored_mode_updated(
  form_id: ID,
  sponsored_enabled: bool,
  updated_at_ms: u64,
) {
  event::emit(SponsoredModeUpdatedEvent { form_id, sponsored_enabled, updated_at_ms });
}
