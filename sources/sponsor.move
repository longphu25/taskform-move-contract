#[allow(lint(custom_state_change, share_owned))]
module taskform::sponsor;

// === Error Codes ===

const ESponsorBudgetExceeded: u64 = 8;

/// Optional sponsor vault for holding funds to sponsor submissions.
/// MVP can use sponsored transaction service instead.
public struct SponsorVault has key, store {
  id: UID,
  form_id: ID,
  owner: address,
  budget_remaining: u64,
  max_submissions: u64,
  used_submissions: u64,
}

// === Public Accessors ===

public fun form_id(vault: &SponsorVault): ID {
  vault.form_id
}

public fun budget_remaining(vault: &SponsorVault): u64 {
  vault.budget_remaining
}

public fun max_submissions(vault: &SponsorVault): u64 {
  vault.max_submissions
}

public fun used_submissions(vault: &SponsorVault): u64 {
  vault.used_submissions
}

public fun can_sponsor(vault: &SponsorVault): bool {
  vault.budget_remaining > 0 && vault.used_submissions < vault.max_submissions
}

// === Package-Internal Functions ===

public(package) fun new(
  form_id: ID,
  owner: address,
  budget: u64,
  max_submissions: u64,
  ctx: &mut TxContext,
): SponsorVault {
  SponsorVault {
    id: object::new(ctx),
    form_id,
    owner,
    budget_remaining: budget,
    max_submissions,
    used_submissions: 0,
  }
}

public(package) fun use_budget(vault: &mut SponsorVault, amount: u64) {
  assert!(vault.budget_remaining >= amount, ESponsorBudgetExceeded);
  assert!(vault.used_submissions < vault.max_submissions, ESponsorBudgetExceeded);
  vault.budget_remaining = vault.budget_remaining - amount;
  vault.used_submissions = vault.used_submissions + 1;
}

public(package) fun share(vault: SponsorVault) {
  transfer::share_object(vault);
}
