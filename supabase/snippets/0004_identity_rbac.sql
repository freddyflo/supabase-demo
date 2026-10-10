create table staff (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  auth_user_id uuid references auth.users(id),
  full_name text not null,
  phone text not null,
  password_hash text,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  unique (organization_id, phone)
);

create table roles (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  permissions jsonb not null default '{}'
);

create table staff_branch_roles (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  staff_id uuid not null references staff(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  role_id uuid not null references roles(id),
  granted_by uuid references staff(id),
  granted_at timestamptz not null default now(),
  expires_at timestamptz,
  unique (staff_id, branch_id, role_id)
);
