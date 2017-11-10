{ data_format: "contact_with_transaction", 
  action_type: "update", 
  match_by: { 
    contact: "first_name_last_name_email"
  }, 
  data_type: "json", 
  data: [{ 
    first_name: "fname", 
    last_name: "lname", 
    email: "email", 
    addr1: "addr1", 
    addr2: "addr2", 
    city: "city", 
    state: "state", 
    postal: "zip",
    country: "country",
    created_at: "create_date",
    amount_in_cents: "amt",
    currency: "usd",
    transaction_time: "create_date",
    campaign_id: "270572",
    fund_id: "27452",
    acknowledged: "false",
    transaction_note: "CauseVox campaign", 
    stripe_charge_id: "stripe_id", 
    transaction_type: "Credit", 
    was_refunded: "false", 
    non_tax_deductible_amount_in_cents: "0", 
    is_donation: "true"
  }]
}