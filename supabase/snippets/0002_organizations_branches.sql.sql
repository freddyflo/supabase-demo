create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  contact_email text,
  contact_phone text,
  status text not null default 'trial',
  whatsapp_assistant_enabled boolean not null default false,
  expiry_alert_windows int[] not null default '{90,60,30}',
  created_at timestamptz not null default now()
);

create table branches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  code text not null,
  is_distribution_hub boolean not null default false,
  address text,
  location geography(point, 4326),
  timezone text not null default 'Africa/Accra',
  default_delivery_fee numeric(12,2),
  delivery_pricing_mode text not null default 'flat',
  delivery_rate_per_km numeric(12,2),
  created_at timestamptz not null default now(),
  unique (organization_id, code)
);
