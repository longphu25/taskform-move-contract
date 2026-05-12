#[test_only]
#[allow(unused_const, duplicate_alias)]
module taskform::submission_tests;

use std::string;
use sui::clock::{Self, Clock};
use sui::test_scenario::{Self as ts, Scenario};
use taskform::capabilities::{CreatorCap, AdminCap};
use taskform::submission::{Self, SubmissionMeta};
use taskform::taskform::{Self, TaskFormRegistry, Form};

const CREATOR: address = @0xA;
const SUBMITTER: address = @0xB;
const ADMIN: address = @0xC;

// Mirror error codes from taskform module
const EFormNotPublished: u64 = 3;
const EInvalidStatus: u64 = 4;
const EInvalidPriority: u64 = 5;

fun create_published_form(scenario: &mut Scenario, clock: &Clock) {
  ts::next_tx(scenario, CREATOR);
  {
    taskform::init_for_testing(ts::ctx(scenario));
  };
  ts::next_tx(scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Submit Test Form"),
      b"schema_blob",
      object::id_from_address(@0x10),
      500,
      clock,
      ts::ctx(scenario),
    );
    ts::return_shared(registry);
  };
  ts::next_tx(scenario, CREATOR);
  {
    let mut form = ts::take_shared<Form>(scenario);
    let cap = ts::take_from_sender<CreatorCap>(scenario);
    taskform::publish_form(&mut form, &cap, clock);
    ts::return_to_sender(scenario, cap);
    ts::return_shared(form);
  };
}

#[test]
fun test_submit_form() {
  let mut scenario = ts::begin(CREATOR);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));

  create_published_form(&mut scenario, &clock);

  // Submit as SUBMITTER
  ts::next_tx(&mut scenario, SUBMITTER);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    taskform::submit_form(
      &mut form,
      b"submission_blob_1",
      object::id_from_address(@0x20),
      600,
      &clock,
      ts::ctx(&mut scenario),
    );
    assert!(taskform::submission_count(&form) == 1);
    ts::return_shared(form);
  };
  // Verify submitter owns SubmissionMeta
  ts::next_tx(&mut scenario, SUBMITTER);
  {
    let sub = ts::take_from_sender<SubmissionMeta>(&scenario);
    assert!(submission::status(&sub) == 0); // STATUS_NEW
    assert!(submission::priority(&sub) == 0); // PRIORITY_LOW
    ts::return_to_sender(&scenario, sub);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test]
fun test_update_submission_status_and_priority() {
  let mut scenario = ts::begin(CREATOR);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));

  create_published_form(&mut scenario, &clock);

  // Submit
  ts::next_tx(&mut scenario, SUBMITTER);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    taskform::submit_form(
      &mut form,
      b"sub_blob",
      object::id_from_address(@0x30),
      700,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(form);
  };

  // Add admin
  ts::next_tx(&mut scenario, CREATOR);
  {
    let form = ts::take_shared<Form>(&scenario);
    let cap = ts::take_from_sender<CreatorCap>(&scenario);
    taskform::add_admin(&form, &cap, ADMIN, &clock, ts::ctx(&mut scenario));
    ts::return_to_sender(&scenario, cap);
    ts::return_shared(form);
  };

  // Admin updates status
  ts::next_tx(&mut scenario, ADMIN);
  {
    let form = ts::take_shared<Form>(&scenario);
    let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
    let mut sub = ts::take_from_address<SubmissionMeta>(&scenario, SUBMITTER);

    taskform::update_submission_status(&form, &mut sub, &admin_cap, 3, &clock); // IN_PROGRESS
    assert!(submission::status(&sub) == 3);

    taskform::update_submission_priority(&form, &mut sub, &admin_cap, 2, &clock); // HIGH
    assert!(submission::priority(&sub) == 2);

    ts::return_to_address(SUBMITTER, sub);
    ts::return_to_sender(&scenario, admin_cap);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test, expected_failure(abort_code = EFormNotPublished, location = taskform)]
fun test_submit_unpublished_form_fails() {
  let mut scenario = ts::begin(CREATOR);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));
  {
    taskform::init_for_testing(ts::ctx(&mut scenario));
  };
  ts::next_tx(&mut scenario, CREATOR);
  {
    let mut registry = ts::take_shared<TaskFormRegistry>(&scenario);
    taskform::create_form(
      &mut registry,
      string::utf8(b"Unpublished Form"),
      b"blob_unpub",
      object::id_from_address(@0x40),
      100,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(registry);
  };
  // Try to submit without publishing
  ts::next_tx(&mut scenario, SUBMITTER);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    taskform::submit_form(
      &mut form,
      b"sub_blob_fail",
      object::id_from_address(@0x50),
      200,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test, expected_failure(abort_code = EInvalidStatus, location = taskform)]
fun test_invalid_status_fails() {
  let mut scenario = ts::begin(CREATOR);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));

  create_published_form(&mut scenario, &clock);

  // Submit
  ts::next_tx(&mut scenario, SUBMITTER);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    taskform::submit_form(
      &mut form,
      b"sub_blob_status",
      object::id_from_address(@0x60),
      800,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(form);
  };

  // Add admin
  ts::next_tx(&mut scenario, CREATOR);
  {
    let form = ts::take_shared<Form>(&scenario);
    let cap = ts::take_from_sender<CreatorCap>(&scenario);
    taskform::add_admin(&form, &cap, ADMIN, &clock, ts::ctx(&mut scenario));
    ts::return_to_sender(&scenario, cap);
    ts::return_shared(form);
  };

  // Try invalid status (6 is out of range)
  ts::next_tx(&mut scenario, ADMIN);
  {
    let form = ts::take_shared<Form>(&scenario);
    let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
    let mut sub = ts::take_from_address<SubmissionMeta>(&scenario, SUBMITTER);

    taskform::update_submission_status(&form, &mut sub, &admin_cap, 6, &clock);

    ts::return_to_address(SUBMITTER, sub);
    ts::return_to_sender(&scenario, admin_cap);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}

#[test, expected_failure(abort_code = EInvalidPriority, location = taskform)]
fun test_invalid_priority_fails() {
  let mut scenario = ts::begin(CREATOR);
  let clock = clock::create_for_testing(ts::ctx(&mut scenario));

  create_published_form(&mut scenario, &clock);

  // Submit
  ts::next_tx(&mut scenario, SUBMITTER);
  {
    let mut form = ts::take_shared<Form>(&scenario);
    taskform::submit_form(
      &mut form,
      b"sub_blob_prio",
      object::id_from_address(@0x70),
      900,
      &clock,
      ts::ctx(&mut scenario),
    );
    ts::return_shared(form);
  };

  // Add admin
  ts::next_tx(&mut scenario, CREATOR);
  {
    let form = ts::take_shared<Form>(&scenario);
    let cap = ts::take_from_sender<CreatorCap>(&scenario);
    taskform::add_admin(&form, &cap, ADMIN, &clock, ts::ctx(&mut scenario));
    ts::return_to_sender(&scenario, cap);
    ts::return_shared(form);
  };

  // Try invalid priority (4 is out of range)
  ts::next_tx(&mut scenario, ADMIN);
  {
    let form = ts::take_shared<Form>(&scenario);
    let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
    let mut sub = ts::take_from_address<SubmissionMeta>(&scenario, SUBMITTER);

    taskform::update_submission_priority(&form, &mut sub, &admin_cap, 4, &clock);

    ts::return_to_address(SUBMITTER, sub);
    ts::return_to_sender(&scenario, admin_cap);
    ts::return_shared(form);
  };
  clock::destroy_for_testing(clock);
  ts::end(scenario);
}
