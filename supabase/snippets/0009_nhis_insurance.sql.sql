create table customers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  surname text not null,
  first_name text not null,
  phone text,
  sex text,
  date_of_birth date,
  created_at timestamptz not null default now()
);

create table insurance_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_by_organization_id uuid references organizations(id),
  created_at timestamptz not null default now()
);

create table customer_insurance_memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  customer_id uuid not null references customers(id) on delete cascade,
  insurance_provider_id uuid not null references insurance_providers(id),
  insurance_number text,
  card_serial_number text,
  card_expiry_date date,
  opd_folder_no text,
  scheme_name text,
  scheme_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (customer_id, insurance_provider_id)
);

create table insurance_provider_medicines (
  id uuid primary key default gen_random_uuid(),
  insurance_provider_id uuid not null references insurance_providers(id) on delete cascade,
  code text,
  generic_name text not null,
  unit_of_pricing text,
  current_price numeric(12,2) not null,
  level_of_prescribing text,
  dosage text,
  created_at timestamptz not null default now(),
  unique (insurance_provider_id, code)
);

create table insurance_medicine_price_history (
  id uuid primary key default gen_random_uuid(),
  insurance_provider_medicine_id uuid not null references insurance_provider_medicines(id) on delete cascade,
  price numeric(12,2) not null,
  effective_date date not null default current_date,
  recorded_at timestamptz not null default now()
);

create table org_product_insurance_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  org_product_id uuid not null references org_products(id) on delete cascade,
  insurance_provider_medicine_id uuid not null references insurance_provider_medicines(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (org_product_id, insurance_provider_medicine_id)
);
