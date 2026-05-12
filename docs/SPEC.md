# Move Contract Specification v4

## Role

TaskForm Move contract is not a database. It is:

```text
Permission layer
+ lifecycle layer
+ metadata pointer layer
+ event indexing layer
+ sponsored mode configuration
```

Walrus stores form data, submissions, screenshots, videos, and encrypted payloads. Seal protects sensitive content. Sui Move controls who can create, publish, submit, manage, and renew.

## Core Principles

- Use object-centric Sui Move design.
- Do not store large form/submission content on-chain.
- Store only Walrus blob pointers and metadata.
- Every `key` object must have `id: UID`.
- Use `CreatorCap` and `AdminCap` for permissions.
- Use events for dashboard indexing.
- Use shared `Form` object for public submission.
- Never emit sensitive content in events.
- Never store raw private fields on-chain.

## Objects

### TaskFormRegistry

```move
struct TaskFormRegistry has key {
    id: UID,
    form_count: u64,
}
```

Purpose:
- Global shared entry point.
- Allows any wallet user to create forms.
- Tracks total form count.
- Emits form creation events.

### Form

```move
struct Form has key, store {
    id: UID,
    creator: address,
    title: String,
    schema_blob_id: vector<u8>,
    schema_blob_object_id: ID,
    expiry_epoch: u64,
    submission_count: u64,
    is_published: bool,
    sponsored_enabled: bool,
}
```

Purpose:
- Represents one form.
- Stores Walrus pointer to form schema.
- Tracks storage expiry.
- Controls public submit through `is_published`.
- Tracks number of submissions.
- Stores sponsored mode flag.

### CreatorCap

```move
struct CreatorCap has key, store {
    id: UID,
    form_id: ID,
}
```

Required for:
- publish form
- unpublish form
- update form metadata
- add/remove admin
- update storage expiry
- configure sponsored mode

Validation:

```move
assert!(cap.form_id == object::id(form), EInvalidCap);
```

### AdminCap

```move
struct AdminCap has key, store {
    id: UID,
    form_id: ID,
}
```

Required for:
- update submission status
- update submission priority
- update admin note pointer

Validation:

```move
assert!(admin_cap.form_id == object::id(form), EInvalidAdminCap);
```

### SubmissionMeta

```move
struct SubmissionMeta has key, store {
    id: UID,
    form_id: ID,
    submission_blob_id: vector<u8>,
    submission_blob_object_id: ID,
    expiry_epoch: u64,
    created_at_ms: u64,
    status: u8,
    priority: u8,
}
```

Purpose:
- Stores pointer to Walrus submission JSON.
- Stores expiry metadata.
- Stores status and priority.
- Supports dashboard indexing.

### Optional SponsorVault

```move
struct SponsorVault has key, store {
    id: UID,
    form_id: ID,
    owner: address,
    budget_remaining: u64,
    max_submissions: u64,
    used_submissions: u64,
}
```

MVP can use sponsored transaction service instead of full SponsorVault.

## Status and Priority

```move
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
```

## Events

```move
struct FormCreatedEvent has copy, drop {
    form_id: ID,
    creator: address,
    schema_blob_id: vector<u8>,
    created_at_ms: u64,
}

struct FormPublishedEvent has copy, drop {
    form_id: ID,
    creator: address,
    published_at_ms: u64,
}

struct FormUnpublishedEvent has copy, drop {
    form_id: ID,
    creator: address,
    unpublished_at_ms: u64,
}

struct SubmissionCreatedEvent has copy, drop {
    form_id: ID,
    submission_id: ID,
    submission_blob_id: vector<u8>,
    submitter: address,
    created_at_ms: u64,
}

struct SubmissionUpdatedEvent has copy, drop {
    form_id: ID,
    submission_id: ID,
    status: u8,
    priority: u8,
    updated_at_ms: u64,
}

struct AdminAddedEvent has copy, drop {
    form_id: ID,
    admin: address,
    added_at_ms: u64,
}

struct StorageRenewedEvent has copy, drop {
    form_id: ID,
    blob_id: vector<u8>,
    new_expiry_epoch: u64,
    renewed_at_ms: u64,
}

struct SponsoredModeUpdatedEvent has copy, drop {
    form_id: ID,
    sponsored_enabled: bool,
    updated_at_ms: u64,
}
```

Rules:
- No raw submission body in events.
- No email/phone/private data in events.
- Use events for dashboard indexing.

## Entry Functions

### create_form

```move
public entry fun create_form(
    registry: &mut TaskFormRegistry,
    title: String,
    schema_blob_id: vector<u8>,
    schema_blob_object_id: ID,
    expiry_epoch: u64,
    clock: &Clock,
    ctx: &mut TxContext
)
```

### publish_form

```move
public entry fun publish_form(
    form: &mut Form,
    cap: &CreatorCap,
    clock: &Clock
)
```

### unpublish_form

```move
public entry fun unpublish_form(
    form: &mut Form,
    cap: &CreatorCap,
    clock: &Clock
)
```

### submit_form

```move
public entry fun submit_form(
    form: &mut Form,
    submission_blob_id: vector<u8>,
    submission_blob_object_id: ID,
    expiry_epoch: u64,
    clock: &Clock,
    ctx: &mut TxContext
)
```

### add_admin

```move
public entry fun add_admin(
    form: &Form,
    cap: &CreatorCap,
    admin: address,
    clock: &Clock,
    ctx: &mut TxContext
)
```

### update_submission_status

```move
public entry fun update_submission_status(
    form: &Form,
    submission: &mut SubmissionMeta,
    admin_cap: &AdminCap,
    status: u8,
    clock: &Clock
)
```

### update_submission_priority

```move
public entry fun update_submission_priority(
    form: &Form,
    submission: &mut SubmissionMeta,
    admin_cap: &AdminCap,
    priority: u8,
    clock: &Clock
)
```

### update_form_storage_expiry

```move
public entry fun update_form_storage_expiry(
    form: &mut Form,
    cap: &CreatorCap,
    new_expiry_epoch: u64,
    clock: &Clock
)
```

### configure_sponsored_mode

```move
public entry fun configure_sponsored_mode(
    form: &mut Form,
    cap: &CreatorCap,
    sponsored_enabled: bool,
    clock: &Clock
)
```

## Error Codes

```move
const EInvalidCap: u64 = 1;
const EInvalidAdminCap: u64 = 2;
const EFormNotPublished: u64 = 3;
const EInvalidStatus: u64 = 4;
const EInvalidPriority: u64 = 5;
const EStorageExpired: u64 = 6;
const ESponsorDisabled: u64 = 7;
const ESponsorBudgetExceeded: u64 = 8;
const EInvalidBlobPointer: u64 = 9;
const ESubmissionFormMismatch: u64 = 10;
```

## Frontend Integration

### create-form.html

```text
Upload schema JSON to Walrus
→ Get schema_blob_id and schema_blob_object_id
→ Call create_form
→ Receive Form object ID and CreatorCap
→ Call publish_form
→ Generate public form link
```

### form.html

```text
Load form metadata
→ Download schema from Walrus
→ Render form
→ Encrypt sensitive fields if needed
→ Upload submission JSON to Walrus
→ Call submit_form
→ Show success
```

### dashboard.html

```text
Query FormCreatedEvent by creator
→ Query SubmissionCreatedEvent by form
→ Download submissions from Walrus
→ Validate with Zod
→ Decrypt sensitive fields if authorized
→ Update status/priority through Move entry function
```

## Package Structure

```text
contract/
├── Move.toml
├── sources/
│   ├── taskform.move
│   ├── errors.move
│   ├── events.move
│   ├── capabilities.move
│   ├── submission.move
│   └── sponsor.move
└── tests/
    ├── taskform_tests.move
    ├── submission_tests.move
    └── sponsor_tests.move
```
