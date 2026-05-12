# TaskForm Move Contract Dev Checklist

Checklist để đảm bảo contract Move đi đúng tinh thần Sui Move: object-centric storage, object ownership, capability-based permission, event indexing, dynamic fields, và metadata pointer đến Walrus.

---

## 1. Core Sui Move Principles

### 1.1 Object-centric Storage

- [ ] Không thiết kế contract như EVM mapping lớn
- [ ] Mỗi form là một Sui object riêng
- [ ] Mỗi submission metadata là object riêng
- [ ] Không lưu nội dung form/submission lớn on-chain
- [ ] Chỉ lưu pointer đến Walrus blob
- [ ] Mọi object đầu vào transaction phải được truyền rõ qua ID/object reference

### 1.2 Object ID and UID

- [ ] Tất cả struct có `key` phải có field đầu tiên là `id: UID`
- [ ] Không tự tạo hoặc tái sử dụng object ID

### 1.3 Abilities

- [ ] Object on-chain phải có `key`
- [ ] Object cần chuyển ownership nên có `store`
- [ ] Event struct nên có `copy, drop`
- [ ] Không gắn `copy` cho capability objects

### 1.4 Entry Functions

- [ ] Dùng `entry fun` cho các hành động người dùng gọi trực tiếp
- [ ] Không expose function public nếu không cần package khác gọi
- [ ] Mỗi entry function phải có assert quyền và trạng thái

### 1.5 Module Initializer

- [ ] Có `init(ctx: &mut TxContext)` để tạo `TaskFormRegistry`
- [ ] Registry được share object
- [ ] Không tạo quá nhiều singleton không cần thiết

---

## 2. Contract Object Model

### 2.1 TaskFormRegistry

- [ ] Registry được tạo trong `init`
- [ ] Registry được share bằng `transfer::share_object`
- [ ] Registry chỉ giữ counter hoặc metadata tối thiểu
- [ ] Không lưu toàn bộ danh sách forms trong vector lớn
- [ ] Khi tạo form, tăng `form_count`
- [ ] Emit `FormCreatedEvent`

### 2.2 Form Object

- [ ] `Form` là object riêng, shared cho public submit
- [ ] Không lưu schema JSON trong `Form`
- [ ] Chỉ lưu `schema_blob_id` và `schema_blob_object_id`
- [ ] Có `expiry_epoch` để quản lý vòng đời Walrus
- [ ] Có `is_published` để chặn submit khi form chưa publish
- [ ] Có `submission_count`

### 2.3 CreatorCap

- [ ] Mint `CreatorCap` khi tạo form
- [ ] Transfer `CreatorCap` cho creator
- [ ] Luôn kiểm tra `cap.form_id == object::id(form)`
- [ ] Không cho copy capability

### 2.4 AdminCap

- [ ] Chỉ CreatorCap holder được cấp AdminCap
- [ ] AdminCap gắn với đúng form ID
- [ ] Có event khi add admin

### 2.5 SubmissionMeta

- [ ] Không lưu response body on-chain
- [ ] Chỉ lưu pointer đến Walrus submission blob
- [ ] Có `form_id`, `expiry_epoch`, `status`, `priority`
- [ ] Có `created_at_ms` từ `Clock`
- [ ] Không cho submit nếu form chưa publish

---

## 3. Event Indexing

- [ ] Emit event khi tạo form
- [ ] Emit event khi publish/unpublish form
- [ ] Emit event khi submit
- [ ] Emit event khi update status/priority
- [ ] Emit event khi renew storage
- [ ] Event không chứa dữ liệu nhạy cảm
- [ ] Event không chứa raw response body

---

## 4. Walrus Pointer Pattern

- [ ] Form schema lưu ở Walrus
- [ ] Submission body lưu ở Walrus
- [ ] Screenshot/video lưu ở Walrus
- [ ] Sensitive payload đã encrypt trước khi upload
- [ ] On-chain chỉ lưu blob ID, blob object ID, expiry epoch
- [ ] Không lưu email/phone/private response on-chain

---

## 5. Storage Lifecycle

- [ ] Khi publish form, lưu `expiry_epoch`
- [ ] Khi submit, lưu `submission expiry_epoch`
- [ ] Có function update expiry metadata sau khi Walrus blob được gia hạn
- [ ] Chỉ CreatorCap holder được update form storage expiry

---

## 6. Sponsored Submission

- [ ] Không để sponsor private key trong frontend
- [ ] Có `sponsored_enabled` trong Form
- [ ] Có fallback self-paid nếu sponsor unavailable
- [ ] Có max file size để tránh drain sponsor budget
- [ ] Transaction payload phải được validate trước khi sponsor ký

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

- [ ] submit_form (chỉ khi `is_published == true`)

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
