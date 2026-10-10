create table master_drug_catalog (
  id uuid primary key default gen_random_uuid(),
  generic_name text not null,
  common_brand_names text[],
  dosage_form text,
  strength text,
  therapeutic_class text,
  is_prescription_only boolean not null default false,
  fda_registration_no text
);

create table org_products (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  master_drug_id uuid references master_drug_catalog(id) on delete set null,
  catalog_sourced boolean not null default false,
  name text not null,
  generic_name text,
  dosage_form text,
  strength text,
  therapeutic_class text,
  sku text,
  barcode text,
  pack_size int not null default 1,
  cost_price_per_pack numeric(12,2),
  unit_cost_price numeric(12,2),
  selling_price_per_pack numeric(12,2),
  unit_selling_price numeric(12,2) not null,
  is_prescription_only boolean not null default false,
  expiry_alert_days int,
  created_at timestamptz not null default now(),
  unique (organization_id, sku)
);

create table branch_products (
  branch_id uuid not null references branches(id) on delete cascade,
  org_product_id uuid not null references org_products(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  shelf_location text,
  reorder_level int not null default 0,
  expiry_alert_days int,
  primary key (branch_id, org_product_id)
);

create table product_batches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  org_product_id uuid not null references org_products(id) on delete cascade,
  batch_number text not null,
  expiry_date date not null,
  received_at timestamptz not null default now(),
  cost_price_per_pack numeric(12,2),
  unit_cost_price numeric(12,2),
  unique (organization_id, branch_id, org_product_id, batch_number, expiry_date)
);

create table stock_movements (
  id uuid not null default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  product_batch_id uuid not null references product_batches(id),
  movement_type text not null,
  quantity_delta int not null,
  reference_id uuid,
  created_by uuid references staff(id),
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

-- First partition — adjust the month to whichever month you're actually
-- launching staging in; the partition-rotation job (Section 3.1) takes over
-- creating future ones from here.
create table stock_movements_2026_10 partition of stock_movements
  for values from ('2026-10-01') to ('2026-11-01');

create table stock_transfers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  from_branch_id uuid not null references branches(id),
  to_branch_id uuid not null references branches(id),
  status text not null default 'requested',
  requested_by uuid references staff(id),
  approved_by uuid references staff(id),
  created_at timestamptz not null default now()
);
