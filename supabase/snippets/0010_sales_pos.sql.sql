create table sales_transactions (
  id uuid not null default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  device_id uuid,
  cashier_id uuid references staff(id),
  total_amount numeric(12,2) not null,
  payment_method text,   -- cash | mobile_money | card | nhis
  status text not null default 'completed',
  created_at timestamptz not null default now(),
  primary key (id, created_at)
) partition by range (created_at);

create table sales_transactions_2026_10 partition of sales_transactions
  for values from ('2026-10-01') to ('2026-11-01');

create table sale_line_items (
  id uuid not null default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  sales_transaction_id uuid not null,
  created_at timestamptz not null,
  org_product_id uuid not null references org_products(id),
  product_batch_id uuid references product_batches(id),
  sold_as text not null default 'unit',
  quantity int not null,
  unit_price numeric(12,2) not null,
  line_total numeric(12,2) not null,
  is_nhis boolean not null default false,
  customer_id uuid references customers(id),
  insurance_provider_medicine_id uuid references insurance_provider_medicines(id),
  insurer_amount numeric(12,2),
  patient_amount numeric(12,2),
  primary key (id, created_at),
  foreign key (sales_transaction_id, created_at)
    references sales_transactions (id, created_at) on delete cascade
) partition by range (created_at);

create table sale_line_items_2026_10 partition of sale_line_items
  for values from ('2026-10-01') to ('2026-11-01');
