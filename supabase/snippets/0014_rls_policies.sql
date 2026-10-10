alter table organizations enable row level security;
create policy tenant_isolation on organizations
  for all using (id = (auth.jwt() ->> 'org_id')::uuid);

-- Same shape, repeated for every tenant-scoped table:
alter table branches enable row level security;
create policy tenant_isolation on branches
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table staff enable row level security;
create policy tenant_isolation on staff
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table staff_branch_roles enable row level security;
create policy tenant_isolation on staff_branch_roles
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table org_products enable row level security;
create policy tenant_isolation on org_products
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table branch_products enable row level security;
create policy tenant_isolation on branch_products
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table product_batches enable row level security;
create policy tenant_isolation on product_batches
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table stock_movements enable row level security;
create policy tenant_isolation on stock_movements
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table stock_transfers enable row level security;
create policy tenant_isolation on stock_transfers
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table suppliers enable row level security;
create policy tenant_isolation on suppliers
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table supplier_invoices enable row level security;
create policy tenant_isolation on supplier_invoices
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table supplier_invoice_line_items enable row level security;
create policy tenant_isolation on supplier_invoice_line_items
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table supplier_payments enable row level security;
create policy tenant_isolation on supplier_payments
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table sales_transactions enable row level security;
create policy tenant_isolation on sales_transactions
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table sale_line_items enable row level security;
create policy tenant_isolation on sale_line_items
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table whatsapp_conversations enable row level security;
create policy tenant_isolation on whatsapp_conversations
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table prescription_uploads enable row level security;
create policy tenant_isolation on prescription_uploads
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table customer_orders enable row level security;
create policy tenant_isolation on customer_orders
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table customer_order_line_items enable row level security;
create policy tenant_isolation on customer_order_line_items
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table branch_devices enable row level security;
create policy tenant_isolation on branch_devices
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table customers enable row level security;
create policy tenant_isolation on customers
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table customer_insurance_memberships enable row level security;
create policy tenant_isolation on customer_insurance_memberships
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

alter table org_product_insurance_links enable row level security;
create policy tenant_isolation on org_product_insurance_links
  for all using (organization_id = (auth.jwt() ->> 'org_id')::uuid);

-- Shared, read-only tables — everyone reads, only service role writes
alter table master_drug_catalog enable row level security;
create policy read_all on master_drug_catalog for select using (true);

alter table roles enable row level security;
create policy read_all on roles for select using (true);

alter table insurance_providers enable row level security;
create policy read_all on insurance_providers for select using (true);

alter table insurance_provider_medicines enable row level security;
create policy read_all on insurance_provider_medicines for select using (true);
