#[test_only]
#[allow(unused_const, duplicate_alias)]
module taskform::sponsor_tests;

use sui::test_scenario as ts;
use taskform::sponsor;

const OWNER: address = @0xA;

// Mirror error code from sponsor module
const ESponsorBudgetExceeded: u64 = 8;

#[test]
fun test_sponsor_vault_creation() {
  let mut scenario = ts::begin(OWNER);
  {
    let form_id = object::id_from_address(@0x100);
    let vault = sponsor::new(
      form_id,
      OWNER,
      1_000_000,
      100,
      ts::ctx(&mut scenario),
    );

    assert!(sponsor::form_id(&vault) == form_id);
    assert!(sponsor::budget_remaining(&vault) == 1_000_000);
    assert!(sponsor::max_submissions(&vault) == 100);
    assert!(sponsor::used_submissions(&vault) == 0);
    assert!(sponsor::can_sponsor(&vault) == true);

    sponsor::share(vault);
  };
  ts::end(scenario);
}

#[test]
fun test_sponsor_use_budget() {
  let mut scenario = ts::begin(OWNER);
  {
    let form_id = object::id_from_address(@0x200);
    let mut vault = sponsor::new(
      form_id,
      OWNER,
      1000,
      5,
      ts::ctx(&mut scenario),
    );

    sponsor::use_budget(&mut vault, 200);
    assert!(sponsor::budget_remaining(&vault) == 800);
    assert!(sponsor::used_submissions(&vault) == 1);
    assert!(sponsor::can_sponsor(&vault) == true);

    sponsor::share(vault);
  };
  ts::end(scenario);
}

#[test, expected_failure(abort_code = ESponsorBudgetExceeded, location = sponsor)]
fun test_sponsor_budget_exceeded() {
  let mut scenario = ts::begin(OWNER);
  {
    let form_id = object::id_from_address(@0x300);
    let mut vault = sponsor::new(
      form_id,
      OWNER,
      100,
      10,
      ts::ctx(&mut scenario),
    );

    // Try to use more than available
    sponsor::use_budget(&mut vault, 200);

    sponsor::share(vault);
  };
  ts::end(scenario);
}

#[test, expected_failure(abort_code = ESponsorBudgetExceeded, location = sponsor)]
fun test_sponsor_max_submissions_exceeded() {
  let mut scenario = ts::begin(OWNER);
  {
    let form_id = object::id_from_address(@0x400);
    let mut vault = sponsor::new(
      form_id,
      OWNER,
      10_000,
      2,
      ts::ctx(&mut scenario),
    );

    sponsor::use_budget(&mut vault, 100);
    sponsor::use_budget(&mut vault, 100);
    // Third should fail — max_submissions is 2
    sponsor::use_budget(&mut vault, 100);

    sponsor::share(vault);
  };
  ts::end(scenario);
}
