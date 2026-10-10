create table branch_devices (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  branch_id uuid not null references branches(id) on delete cascade,
  device_type text not null,
  last_sync_at timestamptz,
  last_health_snapshot jsonb,
  app_version text
);
