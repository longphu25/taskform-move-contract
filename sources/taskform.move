#[allow(lint(public_entry))]
module taskform::taskform;

use std::string::String;
use sui::clock::Clock;
use sui::dynamic_object_field as dof;
use taskform::capabilities::{Self, CreatorCap, AdminCap};
use taskform::events;
use taskform::submission::{Self, SubmissionMeta};

// === Error Codes ===

const EInvalidCap: u64 = 1;
const EFormNotPublished: u64 = 3;
const EInvalidStatus: u64 = 4;
const EInvalidPriority: u64 = 5;
const EInvalidBlobPointer: u64 = 9;
const EInvalidAdminCap: u64 = 2;
const EInvalidAdminNotePointer: u64 = 11;

// === Structs ===

/// Global shared registry. Tracks total form count.
public struct TaskFormRegistry has key {
  id: UID,
  form_count: u64,
}

/// Represents one form. Shared object for public submission access.
public struct Form has key, store {
  id: UID,
  creator: address,
  title: String,
  schema_blob_id: vector<u8>,
  schema_blob_object_id: ID,
  schema_download_id: vector<u8>,
  expiry_epoch: u64,
  submission_count: u64,
  latest_submission_id: ID,
  is_published: bool,
  sponsored_enabled: bool,
}

// === Init ===

/// Creates the shared TaskFormRegistry on package publish.
fun init(ctx: &mut TxContext) {
  let registry = TaskFormRegistry {
    id: object::new(ctx),
    form_count: 0,
  };
  transfer::share_object(registry);
}

// === Public Accessors ===

public fun form_count(registry: &TaskFormRegistry): u64 {
  registry.form_count
}

public fun form_id(form: &Form): ID {
  object::uid_to_inner(&form.id)
}

public fun creator(form: &Form): address {
  form.creator
}

public fun title(form: &Form): String {
  form.title
}

public fun schema_blob_id(form: &Form): vector<u8> {
  form.schema_blob_id
}

public fun schema_download_id(form: &Form): vector<u8> {
  form.schema_download_id
}

public fun is_published(form: &Form): bool {
  form.is_published
}

public fun submission_count(form: &Form): u64 {
  form.submission_count
}

public fun latest_submission_id(form: &Form): ID {
  form.latest_submission_id
}

public fun sponsored_enabled(form: &Form): bool {
  form.sponsored_enabled
}

public fun submission_status(form: &Form, submission_id: ID): u8 {
  let sub = dof::borrow<ID, SubmissionMeta>(&form.id, submission_id);
  submission::status(sub)
}

public fun submission_priority(form: &Form, submission_id: ID): u8 {
  let sub = dof::borrow<ID, SubmissionMeta>(&form.id, submission_id);
  submission::priority(sub)
}

public fun submission_admin_note_blob_id(form: &Form, submission_id: ID): vector<u8> {
  let sub = dof::borrow<ID, SubmissionMeta>(&form.id, submission_id);
  submission::admin_note_blob_id(sub)
}

// === Entry Functions ===

/// Create a new form. Mints a CreatorCap to the sender.
public entry fun create_form(
  registry: &mut TaskFormRegistry,
  title: String,
  schema_blob_id: vector<u8>,
  schema_blob_object_id: ID,
  schema_download_id: vector<u8>,
  expiry_epoch: u64,
  clock: &Clock,
  ctx: &mut TxContext,
) {
  assert!(!std::vector::is_empty(&schema_blob_id), EInvalidBlobPointer);

  let sender = ctx.sender();

  let form = Form {
    id: object::new(ctx),
    creator: sender,
    title,
    schema_blob_id,
    schema_blob_object_id,
    schema_download_id,
    expiry_epoch,
    submission_count: 0,
    latest_submission_id: object::id_from_address(@0x0),
    is_published: false,
    sponsored_enabled: false,
  };

  let form_obj_id = object::uid_to_inner(&form.id);
  let created_at_ms = clock.timestamp_ms();

  // Mint CreatorCap
  let creator_cap = capabilities::new_creator_cap(form_obj_id, ctx);
  capabilities::transfer_creator_cap(creator_cap, sender);

  // Emit event
  events::emit_form_created(form_obj_id, sender, form.schema_blob_id, created_at_ms);

  // Update registry
  registry.form_count = registry.form_count + 1;

  // Share form for public access
  transfer::share_object(form);
}

/// Publish a form (make it publicly submittable).
public entry fun publish_form(form: &mut Form, cap: &CreatorCap, clock: &Clock) {
  assert!(capabilities::form_id(cap) == object::uid_to_inner(&form.id), EInvalidCap);

  form.is_published = true;

  events::emit_form_published(
    object::uid_to_inner(&form.id),
    form.creator,
    clock.timestamp_ms(),
  );
}

/// Unpublish a form (disable public submissions).
public entry fun unpublish_form(form: &mut Form, cap: &CreatorCap, clock: &Clock) {
  assert!(capabilities::form_id(cap) == object::uid_to_inner(&form.id), EInvalidCap);

  form.is_published = false;

  events::emit_form_unpublished(
    object::uid_to_inner(&form.id),
    form.creator,
    clock.timestamp_ms(),
  );
}

/// Submit to a published form. Stores SubmissionMeta as a dynamic object field under Form.
public entry fun submit_form(
  form: &mut Form,
  submission_blob_id: vector<u8>,
  submission_blob_object_id: ID,
  submission_download_id: vector<u8>,
  expiry_epoch: u64,
  clock: &Clock,
  ctx: &mut TxContext,
) {
  assert!(form.is_published, EFormNotPublished);
  assert!(!std::vector::is_empty(&submission_blob_id), EInvalidBlobPointer);

  let sender = ctx.sender();
  let created_at_ms = clock.timestamp_ms();
  let form_obj_id = object::uid_to_inner(&form.id);

  let sub = submission::new(
    form_obj_id,
    sender,
    submission_blob_id,
    submission_blob_object_id,
    submission_download_id,
    expiry_epoch,
    created_at_ms,
    ctx,
  );

  let sub_id = submission::id(&sub);

  events::emit_submission_created(
    form_obj_id,
    sub_id,
    submission::submission_blob_id(&sub),
    sender,
    created_at_ms,
  );

  form.submission_count = form.submission_count + 1;
  form.latest_submission_id = sub_id;

  dof::add(&mut form.id, sub_id, sub);
}

/// Add an admin to a form. Mints an AdminCap to the specified address.
public entry fun add_admin(
  form: &Form,
  cap: &CreatorCap,
  admin: address,
  clock: &Clock,
  ctx: &mut TxContext,
) {
  assert!(capabilities::form_id(cap) == object::uid_to_inner(&form.id), EInvalidCap);

  let form_obj_id = object::uid_to_inner(&form.id);
  let admin_cap = capabilities::new_admin_cap(form_obj_id, ctx);
  capabilities::transfer_admin_cap(admin_cap, admin);

  events::emit_admin_added(form_obj_id, admin, clock.timestamp_ms());
}

/// Update submission status. Requires AdminCap for the form.
public entry fun update_submission_status(
  form: &mut Form,
  admin_cap: &AdminCap,
  submission_id: ID,
  status: u8,
  clock: &Clock,
) {
  assert!(
    capabilities::admin_form_id(admin_cap) == object::uid_to_inner(&form.id),
    EInvalidAdminCap,
  );
  assert!(submission::is_valid_status(status), EInvalidStatus);

  let form_obj_id = object::uid_to_inner(&form.id);
  let submission_meta = dof::borrow_mut<ID, SubmissionMeta>(&mut form.id, submission_id);
  submission::set_status(submission_meta, status);

  events::emit_submission_updated(
    form_obj_id,
    submission::id(submission_meta),
    status,
    submission::priority(submission_meta),
    clock.timestamp_ms(),
  );
}

/// Update submission priority. Requires AdminCap for the form.
public entry fun update_submission_priority(
  form: &mut Form,
  admin_cap: &AdminCap,
  submission_id: ID,
  priority: u8,
  clock: &Clock,
) {
  assert!(
    capabilities::admin_form_id(admin_cap) == object::uid_to_inner(&form.id),
    EInvalidAdminCap,
  );
  assert!(submission::is_valid_priority(priority), EInvalidPriority);

  let form_obj_id = object::uid_to_inner(&form.id);
  let submission_meta = dof::borrow_mut<ID, SubmissionMeta>(&mut form.id, submission_id);
  submission::set_priority(submission_meta, priority);

  events::emit_submission_updated(
    form_obj_id,
    submission::id(submission_meta),
    submission::status(submission_meta),
    priority,
    clock.timestamp_ms(),
  );
}

/// Update admin note pointer. Requires AdminCap for the form.
public entry fun update_submission_admin_note(
  form: &mut Form,
  admin_cap: &AdminCap,
  submission_id: ID,
  note_blob_id: vector<u8>,
  note_blob_object_id: ID,
  clock: &Clock,
) {
  assert!(
    capabilities::admin_form_id(admin_cap) == object::uid_to_inner(&form.id),
    EInvalidAdminCap,
  );
  assert!(!std::vector::is_empty(&note_blob_id), EInvalidAdminNotePointer);

  let updated_at_ms = clock.timestamp_ms();
  let form_obj_id = object::uid_to_inner(&form.id);
  let submission_meta = dof::borrow_mut<ID, SubmissionMeta>(&mut form.id, submission_id);
  submission::set_admin_note(submission_meta, note_blob_id, note_blob_object_id, updated_at_ms);

  events::emit_submission_admin_note_updated(
    form_obj_id,
    submission::id(submission_meta),
    submission::admin_note_blob_id(submission_meta),
    updated_at_ms,
  );
}

/// Update form storage expiry epoch. Requires CreatorCap.
public entry fun update_form_storage_expiry(
  form: &mut Form,
  cap: &CreatorCap,
  new_expiry_epoch: u64,
  clock: &Clock,
) {
  assert!(capabilities::form_id(cap) == object::uid_to_inner(&form.id), EInvalidCap);

  form.expiry_epoch = new_expiry_epoch;

  events::emit_storage_renewed(
    object::uid_to_inner(&form.id),
    form.schema_blob_id,
    new_expiry_epoch,
    clock.timestamp_ms(),
  );
}

/// Configure sponsored mode for a form. Requires CreatorCap.
public entry fun configure_sponsored_mode(
  form: &mut Form,
  cap: &CreatorCap,
  sponsored_enabled: bool,
  clock: &Clock,
) {
  assert!(capabilities::form_id(cap) == object::uid_to_inner(&form.id), EInvalidCap);

  form.sponsored_enabled = sponsored_enabled;

  events::emit_sponsored_mode_updated(
    object::uid_to_inner(&form.id),
    sponsored_enabled,
    clock.timestamp_ms(),
  );
}

// === Test Helpers ===

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
  init(ctx);
}
