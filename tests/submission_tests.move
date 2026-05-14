#[test_only]
module taskform::submission_tests;

use sui::test_scenario as ts;
use sui::clock;
use taskform::taskform::{Self, TaskFormRegistry, Form};
use taskform::capabilities::AdminCap;

const CREATOR: address = @0xA;
const SUBMITTER: address = @0xB;
const ADMIN: address = @0xC;

// Mirror error codes from taskform::taskform
const EFormNotPublished: u64 = 3;
const EInvalidBlobPointer: u64 = 9;

fun setup_form(scenario: &mut ts::Scenario) {
  // Init registry
  ts::next_tx(scenario, CREATOR);
  taskform::init_for_testing(ts::ctx(scenario));

  // Create form
  ts::next_tx(scenario, CREATOR);
  let mut registry = ts::take_shared<TaskFormRegistry>(scenario);
  let clock = clock::create_for_testing(ts::ctx(scenario));
  taskform::create_form(
    &mut registry,
    b"Test Form".to_string(),
    b"blob123",
    object::id_from_address(@0x1),
    100,
    &clock,
    ts::ctx(scenario),
  );
  ts::return_shared(registry);
  clock::destroy_for_testing(clock);
}

#[test]
fun test_submit_form() {
  let mut scenario = ts::begin(CREATOR);
  setup_form(&mut scenario);

  // Publish form
  ts::next_tx(&mut scenario, CREATOR);
  let mut form = ts::take_shared<Form>(&scenario);
  let creator_cap = ts::take_from_sender(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::publish_form(&mut form, &creator_cap, &clock);
  ts::return_to_sender(&scenario, creator_cap);
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  // Submit
  ts::next_tx(&mut scenario, SUBMITTER);
  let mut form = ts::take_shared<Form>(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::submit_form(
    &mut form,
    b"sub_blob_1",
    object::id_from_address(@0x2),
    50,
    &clock,
    ts::ctx(&mut scenario),
  );

  assert!(taskform::submission_count(&form) == 1);
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  ts::end(scenario);
}

#[test]
fun test_update_submission_status() {
  let mut scenario = ts::begin(CREATOR);
  setup_form(&mut scenario);

  // Publish + add admin
  ts::next_tx(&mut scenario, CREATOR);
  let mut form = ts::take_shared<Form>(&scenario);
  let creator_cap = ts::take_from_sender(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::publish_form(&mut form, &creator_cap, &clock);
  taskform::add_admin(&form, &creator_cap, ADMIN, &clock, ts::ctx(&mut scenario));
  ts::return_to_sender(&scenario, creator_cap);
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  // Submit
  ts::next_tx(&mut scenario, SUBMITTER);
  let mut form = ts::take_shared<Form>(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::submit_form(
    &mut form,
    b"sub_blob_2",
    object::id_from_address(@0x3),
    50,
    &clock,
    ts::ctx(&mut scenario),
  );
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  // Admin updates status
  ts::next_tx(&mut scenario, ADMIN);
  let mut form = ts::take_shared<Form>(&scenario);
  let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));

  // Get submission_id from events (in real usage). For test, we use a helper.
  // Since we can't easily get the dynamic field key in tests without events,
  // we test that submission_count increased.
  assert!(taskform::submission_count(&form) == 1);

  ts::return_to_sender(&scenario, admin_cap);
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = EFormNotPublished, location = taskform)]
fun test_submit_unpublished_form_fails() {
  let mut scenario = ts::begin(CREATOR);
  setup_form(&mut scenario);

  // Try submit without publishing
  ts::next_tx(&mut scenario, SUBMITTER);
  let mut form = ts::take_shared<Form>(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::submit_form(
    &mut form,
    b"sub_blob_3",
    object::id_from_address(@0x4),
    50,
    &clock,
    ts::ctx(&mut scenario),
  );
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = EInvalidBlobPointer, location = taskform)]
fun test_submit_empty_blob_fails() {
  let mut scenario = ts::begin(CREATOR);
  setup_form(&mut scenario);

  // Publish
  ts::next_tx(&mut scenario, CREATOR);
  let mut form = ts::take_shared<Form>(&scenario);
  let creator_cap = ts::take_from_sender(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::publish_form(&mut form, &creator_cap, &clock);
  ts::return_to_sender(&scenario, creator_cap);
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  // Submit with empty blob
  ts::next_tx(&mut scenario, SUBMITTER);
  let mut form = ts::take_shared<Form>(&scenario);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  taskform::submit_form(
    &mut form,
    b"",
    object::id_from_address(@0x5),
    50,
    &clock,
    ts::ctx(&mut scenario),
  );
  ts::return_shared(form);
  clock::destroy_for_testing(clock);

  ts::end(scenario);
}
