create table whatsapp_conversations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  customer_phone text not null,
  branch_id uuid references branches(id),
  created_at timestamptz not null default now()
);

create table prescription_uploads (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  conversation_id uuid not null references whatsapp_conversations(id),
  image_storage_path text not null,
  ocr_text text,
  ai_draft_response text,
  status text not null default 'pending_review',
  reviewed_by uuid references staff(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table customer_orders (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  conversation_id uuid not null references whatsapp_conversations(id),
  fulfillment_type text not null,
  status text not null default 'pending',
  payment_status text not null default 'unpaid',
  paystack_reference text unique,
  delivery_address text,
  delivery_fee numeric(12,2),
  cancellation_reason_code text,
  cancellation_reason_note text,
  cancelled_by uuid references staff(id),
  cancelled_at timestamptz,
  refund_reason_code text,
  refund_reason_note text,
  refunded_by uuid references staff(id),
  refunded_at timestamptz,
  created_at timestamptz not null default now(),
  check (status <> 'cancelled' or (cancellation_reason_code is not null and cancelled_by is not null and cancelled_at is not null)),
  check (status <> 'refunded' or (refund_reason_code is not null and refunded_by is not null and refunded_at is not null)),
  check (cancellation_reason_code is distinct from 'other' or cancellation_reason_note is not null),
  check (refund_reason_code is distinct from 'other' or refund_reason_note is not null)
);

create table customer_order_line_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  customer_order_id uuid not null references customer_orders(id) on delete cascade,
  org_product_id uuid not null references org_products(id),
  quantity int not null,
  unit_price numeric(12,2) not null,
  line_total numeric(12,2) not null,
  created_at timestamptz not null default now()
);
