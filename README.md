# TaskForm Move Contract

Sui Move smart contract for TaskForm — the permission, lifecycle, metadata pointer, and event indexing layer.

## Role

Move is **not** a database. It controls:
- **Permissions** — CreatorCap, AdminCap for access control
- **Lifecycle** — Storage expiry tracking (Walrus epochs)
- **Metadata pointers** — Blob IDs pointing to Walrus data
- **Event indexing** — Structured events for dashboard queries
- **Sponsored mode** — Configuration for fee sponsorship

Large data (form schemas, submissions, attachments) lives on **Walrus**.
Sensitive data is encrypted with **Seal** before upload.

Submission metadata is stored as dynamic object fields under each shared `Form`. This lets the
creator dashboard list submissions by form object ID, then download the full submission body from
Walrus only when needed.

## Objects

| Object | Type | Purpose |
|--------|------|---------|
| TaskFormRegistry | shared | Global registry, tracks form count |
| Form | shared | Form metadata + Walrus blob pointers |
| CreatorCap | owned | Proves form ownership |
| AdminCap | owned | Delegated admin access |
| SubmissionMeta | dynamic object field under Form | Submission pointer + status/priority + admin note pointer |
| SponsorVault | optional | Holds sponsor funds (nice-to-have) |

## Entry Functions

| Function | Permission | Purpose |
|----------|-----------|---------|
| `create_form` | any wallet | Create form + mint CreatorCap |
| `publish_form` | CreatorCap | Set form as public |
| `unpublish_form` | CreatorCap | Remove from public |
| `submit_form` | public (if published) | Record submission metadata |
| `add_admin` | CreatorCap | Delegate AdminCap |
| `update_submission_status` | AdminCap | Change status |
| `update_submission_priority` | AdminCap | Change priority |
| `update_submission_admin_note` | AdminCap | Store admin note Walrus pointer |
| `update_form_storage_expiry` | CreatorCap | Update expiry tracking |
| `configure_sponsored_mode` | CreatorCap | Toggle sponsored submissions |

## Package Structure

```
contract/
├── Move.toml
├── sources/
│   ├── taskform.move        # Main module + init
│   ├── errors.move          # Error codes
│   ├── events.move          # Event structs
│   ├── capabilities.move    # CreatorCap, AdminCap
│   ├── submission.move      # SubmissionMeta
│   └── sponsor.move         # SponsorVault (optional)
├── tests/
│   ├── taskform_tests.move
│   ├── submission_tests.move
│   └── sponsor_tests.move
└── docs/
    ├── SPEC.md              # Full contract specification
    └── DEV_CHECKLIST.md     # Development checklist
```

## Quick Start

```bash
# Build
sui move build

# Test
sui move test

# Publish to testnet (default network)
sui client publish --gas-budget 100000000
```

## Network

- Contract is deployed and operates on **Sui testnet**
- All development, testing, and frontend interaction uses testnet
- Walrus Site (frontend hosting) deploys to **mainnet Walrus**

## Deployed (Testnet)

| Item | ID |
|------|-----|
| Package | `0x74c03ba837ce1a8efce0ca36c25a5e734cbfb266a660d1a480a54ad6b02560c6` |
| TaskFormRegistry | `0x217f15103336d13f408caedc8a9b10cd1aa6ee199aab22da7f130fed1e9e3f5f` |
| UpgradeCap | `0x883a127c4bffe45b3a857f9f14677ba49f437e052badcc98d592da0d4f293284` |

## Documentation

- `docs/SPEC.md` — Full contract specification with all structs, events, entry functions
- `docs/DEV_CHECKLIST.md` — Development checklist covering Sui Move best practices

## Frontend Integration

```text
create-form.html:  Upload schema → Walrus → create_form → publish_form → public link
form.html:         Load schema → Walrus → render → encrypt → upload → submit_form
dashboard.html:    List Form dynamic fields → fetch SubmissionMeta → download Walrus body → decrypt/review/export
```
