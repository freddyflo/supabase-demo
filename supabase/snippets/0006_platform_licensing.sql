create table platform.licenses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  plan text not null,
  contracted_branch_count int not null,
  status text not null default 'active',
  current_period_end timestamptz not null,
  grace_period_days int not null default 10,
  created_at timestamptz not null default now()
);

create table platform.branch_installations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  activation_code text not null unique,
  hardware_fingerprint text,
  activated_at timestamptz,
  last_checkin_at timestamptz,
  app_version text,
  status text not null default 'pending'
);

create table platform.tenant_paystack_accounts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade unique,
  paystack_subaccount_code text not null,
  webhook_secret text not null,
  created_at timestamptz not null default now()
);
