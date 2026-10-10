create table suppliers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  contact_name text,
  phone text,
  email text,
  address text,
  created_at timestamptz not null default now()
);

create table supplier_invoices (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  supplier_id uuid not null references suppliers(id),
  invoice_number text not null,
  invoice_date date not null,
  received_by uuid references staff(id),
  total_amount numeric(12,2) not null,
  amount_paid numeric(12,2) not null default 0,
  payment_status text not null default 'unpaid',
  created_at timestamptz not null default now(),
  unique (organization_id, supplier_id, invoice_number)
);

create table supplier_invoice_line_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  supplier_invoice_id uuid not null references supplier_invoices(id) on delete cascade,
  org_product_id uuid not null references org_products(id),
  product_batch_id uuid not null references product_batches(id),
  quantity int not null,
  unit_cost_price numeric(12,2) not null,
  cost_price_per_pack numeric(12,2),
  line_total numeric(12,2) not null,
  created_at timestamptz not null default now()
);

create table supplier_payments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  supplier_invoice_id uuid not null references supplier_invoices(id) on delete cascade,
  amount numeric(12,2) not null,
  payment_method text,
  paid_by uuid references staff(id),
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
