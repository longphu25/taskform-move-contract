# TaskForm Move Contract Dev Checklist

Checklist to ensure the Move contract follows Sui Move principles: object-centric storage, object ownership, capability-based permissions, event indexing, dynamic fields, and metadata pointers to Walrus.

---

## 1. Core Sui Move Principles

### 1.1 Object-centric Storage

- [ ] Do not design the contract like a large EVM mapping
- [ ] Each form is a separate Sui object
- [ ] Each submission metadata is a separate object
- [ ] Do not store large form/submission content on-chain
- [ ] Only store pointers to Walrus blobs
- [ ] All transaction input objects must be passed explicitly via ID/object reference

### 1.2 Object ID and UID

- [ ] All structs with `key` must have `id: UID` as the first field
- [ ] Do not manually create or reuse object IDs

### 1.3 Abilities

- [ ] On-chain objects must have `key`
- [ ] Objects that need ownership transfer should have `store`
- [ ] Event structs should have `copy, drop`
- [ ] Do not attach `copy` to capability objects

### 1.4 Entry Functions

- [ ] Use `entry fun` for actions users call directly
- [ ] Do not expose functions as public unless another package needs to call them
- [ ] Each entry function must assert permissions and state

### 1.5 Module Initializer

- [ ] Has `init(ctx: &mut TxContext)` to create `TaskFormRegistry`
- [ ] Registry is a shared object
- [ ] Do not create unnecessary singletons

---

## 2. Contract Object Model

### 2.1 TaskFormRegistry

- [ ] Registry is created in `init`
- [ ] Registry is shared via `transfer::share_object`
- [ ] Registry only holds counter or minimal metadata
- [ ] Do not store the entire forms list in a large vector
- [ ] Increment `form_count` when creating a form
- [ ] Emit `FormCreatedEvent`

### 2.2 Form Object

- [ ] `Form` is a separate object, shared for public submit
- [ ] Do not store schema JSON in `Form`
- [ ] Only store `schema_blob_id` and `schema_blob_object_id`
- [ ] Has `expiry_epoch` for Walrus lifecycle management
- [ ] Has `is_published` to block submit when form is not published
- [ ] Has `submission_count`

### 2.3 CreatorCap

- [ ] Mint `CreatorCap` when creating a form
- [ ] Transfer `CreatorCap` to creator
- [ ] Always check `cap.form_id == object::id(form)`
- [ ] Do not allow copying the capability

### 2.4 AdminCap

- [ ] Only CreatorCap holder can grant AdminCap
- [ ] AdminCap is bound to the correct form ID
- [ ] Emit event when adding admin

### 2.5 SubmissionMeta

- [ ] Do not store response body on-chain
- [ ] Only store pointer to Walrus submission blob
- [ ] Has `form_id`, `expiry_epoch`, `status`, `priority`
- [ ] Has `created_at_ms` from `Clock`
- [ ] Do not allow submit if form is not published

---

## 3. Event Indexing

- [ ] Emit event when creating form
- [ ] Emit event when publishing/unpublishing form
- [ ] Emit event when submitting
- [ ] Emit event when updating status/priority
- [ ] Emit event when renewing storage
- [ ] Events must not contain sensitive data
- [ ] Events must not contain raw response body

---

## 4. Walrus Pointer Pattern

- [ ] Form schema stored on Walrus
- [ ] Submission body stored on Walrus
- [ ] Screenshots/videos stored on Walrus
- [ ] Sensitive payload encrypted before upload
- [ ] On-chain only stores blob ID, blob object ID, expiry epoch
- [ ] Do not store email/phone/private responses on-chain

---

## 5. Storage Lifecycle

- [ ] When publishing form, store `expiry_epoch`
- [ ] When submitting, store `submission expiry_epoch`
- [ ] Has function to update expiry metadata after Walrus blob renewal
- [ ] Only CreatorCap holder can update form storage expiry

---

## 6. Sponsored Submission

- [ ] Do not put sponsor private key in frontend
- [ ] Has `sponsored_enabled` in Form
- [ ] Has self-paid fallback if sponsor unavailable
- [ ] Has max file size to prevent draining sponsor budget
- [ ] Transaction payload must be validated before sponsor signs

---

## 7. Access Control

### Creator-only Actions

- [ ] publish_form
- [ ] unpublish_form
- [ ] add_admin
- [ ] update_form_metadata
- [ ] update_storage_expiry
- [ ] configure_sponsored_mode

### Admin Actions

- [ ] update_submission_status
- [ ] update_submission_priority

### Public Actions

- [ ] submit_form (only when `is_published == true`)

---

## 8. Testing

### Unit Tests

- [ ] create registry on init
- [ ] create form → creator receives CreatorCap
- [ ] publish with valid CreatorCap succeeds
- [ ] publish with wrong CreatorCap fails
- [ ] submit unpublished form fails
- [ ] submit published form succeeds
- [ ] submission_count increments
- [ ] event emitted on submit
- [ ] add admin with CreatorCap succeeds
- [ ] update status with AdminCap succeeds
- [ ] invalid status fails
- [ ] invalid priority fails
- [ ] update storage expiry with CreatorCap succeeds

### Negative Tests

- [ ] Wrong cap for another form
- [ ] Submit with empty blob ID
- [ ] Submit to unpublished form
- [ ] Update status with invalid enum
- [ ] Add admin with wrong cap

---

## 9. Deployment

- [ ] `sui move build` passes
- [ ] `sui move test` passes
- [ ] Package published on testnet
- [ ] Package ID saved in frontend env
- [ ] Registry object ID saved in frontend env
- [ ] Event type names saved for query
- [ ] Demo seed data prepared

---

## 10. MVP Scope

### Must Have

- [ ] TaskFormRegistry
- [ ] Form
- [ ] CreatorCap
- [ ] AdminCap
- [ ] SubmissionMeta
- [ ] create_form
- [ ] publish_form
- [ ] unpublish_form
- [ ] submit_form
- [ ] add_admin
- [ ] update_submission_status
- [ ] update_submission_priority
- [ ] update_form_storage_expiry
- [ ] events
- [ ] tests

### Should Have

- [ ] revoke_admin
- [ ] sponsor mode config
- [ ] storage renewal event

### Nice to Have

- [ ] SponsorVault
- [ ] batch status update
- [ ] form versioning
- [ ] transfer creator ownership
