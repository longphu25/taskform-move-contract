#[test_only]
#[allow(unused_const, duplicate_alias)]
module taskform::taskform_tests;

use std::string;
use sui::clock::{Self, Clock};
use sui::test_scenario::{Self as ts, Scenario};
use taskform::capabilities::{Self as caps, CreatorCap};
use taskform::taskform::{Self, TaskFormRegistry, Form};

const CREATOR: address = @0xA;
const USER: address = @0xB;

// Mirror error codes from taskform module
const EInvalidCap: u64 = 1;
const EInvalidBlobPointer: u64 = 9;

fun setup(scenario: &mut Scenario): Clock {
  let mut clock = clock::create_for_testing(ts::ctx(scenario));
  clock::set_for_testing(&mut clock, 1000);
  clock
}

#[test]
fun test_init_creates_registry() {
  let mut scenario = ts::begin(CREATOR);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let registry = ts::take_shared<TaskFormRegistry>(&scenario);
    assert!(taskform::form_count(&registry) == 0);
    ts::return_shared(registry);
  };
  ts::end(scenario);
}

#[test]
fun test_create_form() {
  let mut scenario = ts::begin(CREATOR);
  let clock = setup(&mut scenario);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    let schema_blob_id = b"blob123";
    let schema_blob_object_id = object::id_from_address(@0x1);

    taskform::create_form(
      &mut registry,
      string::utf8(b"Test Form"),
      schema_blob_id,
      schema_blob_object_id,
      100,
      &clock,
      ts::ctx(&mut scenario),
    );

    assert!(taskform::form_count(&registry) == 1);
    ts::return_shared(registry);
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let cap = ts::take_from_sender<CreatorCap>(&scenario);
    ts::return_to_sender(&scenario, cap);

    let form = ts::take_shared<Form>(&scenario);
    assert!(taskform::creator(&form) == CREATOR);
    assert!(taskform::title(&form) == string::utf8(b"Test Form"));
    assert!(taskform::is_published(&form) == false);
    assert!(taskform::submission_count(&form) == 0);
    assert!(taskform::sponsored_enabled(&form) == false);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test]
fun test_publish_and_unpublish() {
  let mut scenario = ts::begin(CREATOR);
  let clock = setup(&mut scenario);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"My Form"),
      b"blob456",
      object::id_from_address(@0x2),
      200,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    let cap = ts::take_from_sender<CreatorCap>(&scenario);

    taskform::publish_form(&mut form, &cap, &clock);
    assert!(taskform::is_published(&form) == true);

    taskform::unpublish_form(&mut form, &cap, &clock);
    assert!(taskform::is_published(&form) == false);

    ts::return_to_sender(&scenario, cap);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test]
fun test_configure_sponsored_mode() {
  let mut scenario = ts::begin(CREATOR);
  let clock = setup(&mut scenario);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Sponsored Form"),
      b"blob789",
      object::id_from_address(@0x3),
      300,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    let cap = ts::take_from_sender<CreatorCap>(&scenario);

    taskform::configure_sponsored_mode(&mut form, &cap, true, &clock);
    assert!(taskform::sponsored_enabled(&form) == true);

    taskform::configure_sponsored_mode(&mut form, &cap, false, &clock);
    assert!(taskform::sponsored_enabled(&form) == false);

    ts::return_to_sender(&scenario, cap);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test]
fun test_update_storage_expiry() {
  let mut scenario = ts::begin(CREATOR);
  let clock = setup(&mut scenario);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Expiry Form"),
      b"blobAAA",
      object::id_from_address(@0x4),
      100,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    let cap = ts::take_from_sender<CreatorCap>(&scenario);

    taskform::update_form_storage_expiry(&mut form, &cap, 500, &clock);

    ts::return_to_sender(&scenario, cap);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test, expected_failure(abort_code = EInvalidCap, location = taskform)]
fun test_publish_wrong_cap_fails() {
  let mut scenario = ts::begin(CREATOR);
  let clock = setup(&mut scenario);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  // Create form as CREATOR
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Form A"),
      b"blobA",
      object::id_from_address(@0x5),
      100,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  // Create form as USER
  ts::next_tx(&mut scenario, USER);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Form B"),
      b"blobB",
      object::id_from_address(@0x6),
      100,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  // CREATOR tries to publish Form A using USER's cap (for Form B)
  ts::next_tx(&mut scenario, CREATOR);
  {
    // Get CREATOR's cap to find Form A's ID
    let creator_cap = ts::take_from_sender<CreatorCap>(&scenario);
    let form_a_id = caps::form_id(&creator_cap);
    ts::return_to_sender(&scenario, creator_cap);

    // Take Form A specifically
    let mut form_a = ts::take_shared_by_id<Form>(&scenario, form_a_id);
    // Take USER's cap (for Form B) — mismatch
    let wrong_cap = ts::take_from_address<CreatorCap>(&scenario, USER);

    // Should abort: wrong_cap.form_id != form_a.id
    taskform::publish_form(&mut form_a, &wrong_cap, &clock);

    ts::return_to_address(USER, wrong_cap);
    ts::return_shared(form_a);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test, expected_failure(abort_code = EInvalidBlobPointer, location = taskform)]
fun test_create_form_empty_blob_fails() {
  let mut scenario = ts::begin(CREATOR);
  let clock = setup(&mut scenario);
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Bad Form"),
      b"",
      object::id_from_address(@0x7),
      100,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}
