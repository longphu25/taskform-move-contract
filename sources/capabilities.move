#[allow(lint(custom_state_change))]
module taskform::capabilities;

/// Proves ownership of a Form. Required for publish, unpublish, add admin, update expiry, configure sponsored.
public struct CreatorCap has key, store {
  id: UID,
  form_id: ID,
}

/// Delegated admin access. Required for updating submission status/priority.
public struct AdminCap has key, store {
  id: UID,
  form_id: ID,
}

// === Public Accessors ===

public fun form_id(cap: &CreatorCap): ID {
  cap.form_id
}

public fun admin_form_id(cap: &AdminCap): ID {
  cap.form_id
}

// === Package-Internal Constructors ===

public(package) fun new_creator_cap(form_id: ID, ctx: &mut TxContext): CreatorCap {
  CreatorCap {
    id: object::new(ctx),
    form_id,
  }
}

public(package) fun new_admin_cap(form_id: ID, ctx: &mut TxContext): AdminCap {
  AdminCap {
    id: object::new(ctx),
    form_id,
  }
}

public(package) fun transfer_creator_cap(cap: CreatorCap, recipient: address) {
  transfer::transfer(cap, recipient);
}

public(package) fun transfer_admin_cap(cap: AdminCap, recipient: address) {
  transfer::transfer(cap, recipient);
}
