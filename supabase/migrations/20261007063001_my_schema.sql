SET local check_function_bodies = off;

CREATE SCHEMA "platform";

CREATE EXTENSION "postgis" SCHEMA "public";

CREATE TABLE "platform"."branch_installations" (
  "id"                   uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"      uuid                     NOT NULL,
  "branch_id"            uuid                     NOT NULL,
  "activation_code"      text                     NOT NULL,
  "hardware_fingerprint" text,
  "activated_at"         timestamp with time zone,
  "last_checkin_at"      timestamp with time zone,
  "app_version"          text,
  "status"               text                     NOT NULL DEFAULT 'pending'::text,
  CONSTRAINT "branch_installations_activation_code_key" UNIQUE (activation_code),
  CONSTRAINT "branch_installations_pkey" PRIMARY KEY (id)
);

ALTER TABLE "platform"."branch_installations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "platform"."licenses" (
  "id"                      uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"         uuid                     NOT NULL,
  "plan"                    text                     NOT NULL,
  "contracted_branch_count" integer                  NOT NULL,
  "status"                  text                     NOT NULL DEFAULT 'active'::text,
  "current_period_end"      timestamp with time zone NOT NULL,
  "grace_period_days"       integer                  NOT NULL DEFAULT 10,
  "created_at"              timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "licenses_pkey" PRIMARY KEY (id)
);

ALTER TABLE "platform"."licenses"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "platform"."tenant_paystack_accounts" (
  "id"                       uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"          uuid                     NOT NULL,
  "paystack_subaccount_code" text                     NOT NULL,
  "webhook_secret"           text                     NOT NULL,
  "created_at"               timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "tenant_paystack_accounts_organization_id_key" UNIQUE (organization_id),
  CONSTRAINT "tenant_paystack_accounts_pkey" PRIMARY KEY (id)
);

ALTER TABLE "platform"."tenant_paystack_accounts"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."branch_devices" (
  "id"                   uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"      uuid                     NOT NULL,
  "branch_id"            uuid                     NOT NULL,
  "device_type"          text                     NOT NULL,
  "last_sync_at"         timestamp with time zone,
  "last_health_snapshot" jsonb,
  "app_version"          text,
  CONSTRAINT "branch_devices_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."branch_devices"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."branch_products" (
  "branch_id"         uuid    NOT NULL,
  "org_product_id"    uuid    NOT NULL,
  "organization_id"   uuid    NOT NULL,
  "shelf_location"    text,
  "reorder_level"     integer NOT NULL DEFAULT 0,
  "expiry_alert_days" integer,
  CONSTRAINT "branch_products_pkey" PRIMARY KEY (branch_id, org_product_id)
);

ALTER TABLE "public"."branch_products"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."branches" (
  "id"                    uuid                         NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"       uuid                         NOT NULL,
  "name"                  text                         NOT NULL,
  "code"                  text                         NOT NULL,
  "is_distribution_hub"   boolean                      NOT NULL DEFAULT false,
  "address"               text,
  "location"              public.geography(Point,4326),
  "timezone"              text                         NOT NULL DEFAULT 'Africa/Accra'::text,
  "default_delivery_fee"  numeric(12,2),
  "delivery_pricing_mode" text                         NOT NULL DEFAULT 'flat'::text,
  "delivery_rate_per_km"  numeric(12,2),
  "created_at"            timestamp with time zone     NOT NULL DEFAULT now(),
  CONSTRAINT "branches_organization_id_code_key" UNIQUE (organization_id, code),
  CONSTRAINT "branches_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."branches"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."customer_insurance_memberships" (
  "id"                    uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"       uuid                     NOT NULL,
  "customer_id"           uuid                     NOT NULL,
  "insurance_provider_id" uuid                     NOT NULL,
  "insurance_number"      text,
  "card_serial_number"    text,
  "card_expiry_date"      date,
  "opd_folder_no"         text,
  "scheme_name"           text,
  "scheme_code"           text,
  "created_at"            timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"            timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "customer_insurance_membership_customer_id_insurance_provide_key" UNIQUE (customer_id, insurance_provider_id),
  CONSTRAINT "customer_insurance_memberships_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."customer_insurance_memberships"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."customer_order_line_items" (
  "id"                uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"   uuid                     NOT NULL,
  "branch_id"         uuid                     NOT NULL,
  "customer_order_id" uuid                     NOT NULL,
  "org_product_id"    uuid                     NOT NULL,
  "quantity"          integer                  NOT NULL,
  "unit_price"        numeric(12,2)            NOT NULL,
  "line_total"        numeric(12,2)            NOT NULL,
  "created_at"        timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "customer_order_line_items_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."customer_order_line_items"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."customer_orders" (
  "id"                       uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"          uuid                     NOT NULL,
  "branch_id"                uuid                     NOT NULL,
  "conversation_id"          uuid                     NOT NULL,
  "fulfillment_type"         text                     NOT NULL,
  "status"                   text                     NOT NULL DEFAULT 'pending'::text,
  "payment_status"           text                     NOT NULL DEFAULT 'unpaid'::text,
  "paystack_reference"       text,
  "delivery_address"         text,
  "delivery_fee"             numeric(12,2),
  "cancellation_reason_code" text,
  "cancellation_reason_note" text,
  "cancelled_by"             uuid,
  "cancelled_at"             timestamp with time zone,
  "refund_reason_code"       text,
  "refund_reason_note"       text,
  "refunded_by"              uuid,
  "refunded_at"              timestamp with time zone,
  "created_at"               timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "customer_orders_check1" CHECK (((status <> 'refunded'::text) OR ((refund_reason_code IS NOT NULL) AND (refunded_by IS NOT NULL) AND (refunded_at IS NOT NULL)))),
  CONSTRAINT "customer_orders_check2" CHECK (((cancellation_reason_code IS DISTINCT FROM 'other'::text) OR (cancellation_reason_note IS NOT NULL))),
  CONSTRAINT "customer_orders_check3" CHECK (((refund_reason_code IS DISTINCT FROM 'other'::text) OR (refund_reason_note IS NOT NULL))),
  CONSTRAINT "customer_orders_check" CHECK (((status <> 'cancelled'::text) OR ((cancellation_reason_code IS NOT NULL) AND (cancelled_by IS NOT NULL) AND (cancelled_at IS
    NOT NULL)))),
  CONSTRAINT "customer_orders_paystack_reference_key" UNIQUE (paystack_reference),
  CONSTRAINT "customer_orders_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."customer_orders"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."customers" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "surname"         text                     NOT NULL,
  "first_name"      text                     NOT NULL,
  "phone"           text,
  "sex"             text,
  "date_of_birth"   date,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "customers_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."customers"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."insurance_medicine_price_history" (
  "id"                             uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "insurance_provider_medicine_id" uuid                     NOT NULL,
  "price"                          numeric(12,2)            NOT NULL,
  "effective_date"                 date                     NOT NULL DEFAULT CURRENT_DATE,
  "recorded_at"                    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "insurance_medicine_price_history_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."insurance_medicine_price_history"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."insurance_provider_medicines" (
  "id"                    uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "insurance_provider_id" uuid                     NOT NULL,
  "code"                  text,
  "generic_name"          text                     NOT NULL,
  "unit_of_pricing"       text,
  "current_price"         numeric(12,2)            NOT NULL,
  "level_of_prescribing"  text,
  "dosage"                text,
  "created_at"            timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "insurance_provider_medicines_insurance_provider_id_code_key" UNIQUE (insurance_provider_id, code),
  CONSTRAINT "insurance_provider_medicines_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."insurance_provider_medicines"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."insurance_providers" (
  "id"                         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "name"                       text                     NOT NULL,
  "created_by_organization_id" uuid,
  "created_at"                 timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "insurance_providers_name_key" UNIQUE (name),
  CONSTRAINT "insurance_providers_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."insurance_providers"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."master_drug_catalog" (
  "id"                   uuid    NOT NULL DEFAULT gen_random_uuid(),
  "generic_name"         text    NOT NULL,
  "common_brand_names"   text[],
  "dosage_form"          text,
  "strength"             text,
  "therapeutic_class"    text,
  "is_prescription_only" boolean NOT NULL DEFAULT false,
  "fda_registration_no"  text,
  CONSTRAINT "master_drug_catalog_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."master_drug_catalog"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."org_product_insurance_links" (
  "id"                             uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"                uuid                     NOT NULL,
  "org_product_id"                 uuid                     NOT NULL,
  "insurance_provider_medicine_id" uuid                     NOT NULL,
  "created_at"                     timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "org_product_insurance_links_org_product_id_insurance_provid_key" UNIQUE (org_product_id, insurance_provider_medicine_id),
  CONSTRAINT "org_product_insurance_links_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."org_product_insurance_links"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."org_products" (
  "id"                     uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"        uuid                     NOT NULL,
  "master_drug_id"         uuid,
  "catalog_sourced"        boolean                  NOT NULL DEFAULT false,
  "name"                   text                     NOT NULL,
  "generic_name"           text,
  "dosage_form"            text,
  "strength"               text,
  "therapeutic_class"      text,
  "sku"                    text,
  "barcode"                text,
  "pack_size"              integer                  NOT NULL DEFAULT 1,
  "cost_price_per_pack"    numeric(12,2),
  "unit_cost_price"        numeric(12,2),
  "selling_price_per_pack" numeric(12,2),
  "unit_selling_price"     numeric(12,2)            NOT NULL,
  "is_prescription_only"   boolean                  NOT NULL DEFAULT false,
  "expiry_alert_days"      integer,
  "created_at"             timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "org_products_organization_id_sku_key" UNIQUE (organization_id, sku),
  CONSTRAINT "org_products_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."org_products"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."organizations" (
  "id"                         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "name"                       text                     NOT NULL,
  "slug"                       text                     NOT NULL,
  "contact_email"              text,
  "contact_phone"              text,
  "status"                     text                     NOT NULL DEFAULT 'trial'::text,
  "whatsapp_assistant_enabled" boolean                  NOT NULL DEFAULT false,
  "expiry_alert_windows"       integer[]                NOT NULL DEFAULT '{90,60,30}'::integer[],
  "created_at"                 timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "organizations_pkey" PRIMARY KEY (id),
  CONSTRAINT "organizations_slug_key" UNIQUE (slug)
);

ALTER TABLE "public"."organizations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."prescription_uploads" (
  "id"                 uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"    uuid                     NOT NULL,
  "conversation_id"    uuid                     NOT NULL,
  "image_storage_path" text                     NOT NULL,
  "ocr_text"           text,
  "ai_draft_response"  text,
  "status"             text                     NOT NULL DEFAULT 'pending_review'::text,
  "reviewed_by"        uuid,
  "reviewed_at"        timestamp with time zone,
  "created_at"         timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "prescription_uploads_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."prescription_uploads"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."product_batches" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"     uuid                     NOT NULL,
  "branch_id"           uuid                     NOT NULL,
  "org_product_id"      uuid                     NOT NULL,
  "batch_number"        text                     NOT NULL,
  "expiry_date"         date                     NOT NULL,
  "received_at"         timestamp with time zone NOT NULL DEFAULT now(),
  "cost_price_per_pack" numeric(12,2),
  "unit_cost_price"     numeric(12,2),
  CONSTRAINT "product_batches_organization_id_branch_id_org_product_id_ba_key" UNIQUE (organization_id, branch_id, org_product_id, batch_number, expiry_date),
  CONSTRAINT "product_batches_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."product_batches"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."roles" (
  "id"          uuid  NOT NULL DEFAULT gen_random_uuid(),
  "name"        text  NOT NULL,
  "permissions" jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT "roles_name_key" UNIQUE (name),
  CONSTRAINT "roles_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."roles"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."sale_line_items" (
  "id"                             uuid                     NOT NULL,
  "organization_id"                uuid                     NOT NULL,
  "branch_id"                      uuid                     NOT NULL,
  "sales_transaction_id"           uuid                     NOT NULL,
  "created_at"                     timestamp with time zone NOT NULL,
  "org_product_id"                 uuid                     NOT NULL,
  "product_batch_id"               uuid,
  "sold_as"                        text                     NOT NULL,
  "quantity"                       integer                  NOT NULL,
  "unit_price"                     numeric(12,2)            NOT NULL,
  "line_total"                     numeric(12,2)            NOT NULL,
  "is_nhis"                        boolean                  NOT NULL,
  "customer_id"                    uuid,
  "insurance_provider_medicine_id" uuid,
  "insurer_amount"                 numeric(12,2),
  "patient_amount"                 numeric(12,2)
) PARTITION BY RANGE (created_at);

ALTER TABLE "public"."sale_line_items"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."sales_transactions" (
  "id"              uuid                     NOT NULL,
  "organization_id" uuid                     NOT NULL,
  "branch_id"       uuid                     NOT NULL,
  "device_id"       uuid,
  "cashier_id"      uuid,
  "total_amount"    numeric(12,2)            NOT NULL,
  "payment_method"  text,
  "status"          text                     NOT NULL,
  "created_at"      timestamp with time zone NOT NULL
) PARTITION BY RANGE (created_at);

ALTER TABLE "public"."sales_transactions"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."staff_branch_roles" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "staff_id"        uuid                     NOT NULL,
  "branch_id"       uuid                     NOT NULL,
  "role_id"         uuid                     NOT NULL,
  "granted_by"      uuid,
  "granted_at"      timestamp with time zone NOT NULL DEFAULT now(),
  "expires_at"      timestamp with time zone,
  CONSTRAINT "staff_branch_roles_pkey" PRIMARY KEY (id),
  CONSTRAINT "staff_branch_roles_staff_id_branch_id_role_id_key" UNIQUE (staff_id, branch_id, role_id)
);

ALTER TABLE "public"."staff_branch_roles"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."staff" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "auth_user_id"    uuid,
  "full_name"       text                     NOT NULL,
  "phone"           text                     NOT NULL,
  "password_hash"   text,
  "status"          text                     NOT NULL DEFAULT 'active'::text,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "staff_organization_id_phone_key" UNIQUE (organization_id, phone),
  CONSTRAINT "staff_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."staff"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."stock_movements" (
  "id"               uuid                     NOT NULL,
  "organization_id"  uuid                     NOT NULL,
  "branch_id"        uuid                     NOT NULL,
  "product_batch_id" uuid                     NOT NULL,
  "movement_type"    text                     NOT NULL,
  "quantity_delta"   integer                  NOT NULL,
  "reference_id"     uuid,
  "created_by"       uuid,
  "created_at"       timestamp with time zone NOT NULL
) PARTITION BY RANGE (created_at);

ALTER TABLE "public"."stock_movements"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."stock_transfers" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "from_branch_id"  uuid                     NOT NULL,
  "to_branch_id"    uuid                     NOT NULL,
  "status"          text                     NOT NULL DEFAULT 'requested'::text,
  "requested_by"    uuid,
  "approved_by"     uuid,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "stock_transfers_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."stock_transfers"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."supplier_invoice_line_items" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"     uuid                     NOT NULL,
  "branch_id"           uuid                     NOT NULL,
  "supplier_invoice_id" uuid                     NOT NULL,
  "org_product_id"      uuid                     NOT NULL,
  "product_batch_id"    uuid                     NOT NULL,
  "quantity"            integer                  NOT NULL,
  "unit_cost_price"     numeric(12,2)            NOT NULL,
  "cost_price_per_pack" numeric(12,2),
  "line_total"          numeric(12,2)            NOT NULL,
  "created_at"          timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "supplier_invoice_line_items_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."supplier_invoice_line_items"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."supplier_invoices" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "branch_id"       uuid                     NOT NULL,
  "supplier_id"     uuid                     NOT NULL,
  "invoice_number"  text                     NOT NULL,
  "invoice_date"    date                     NOT NULL,
  "received_by"     uuid,
  "total_amount"    numeric(12,2)            NOT NULL,
  "amount_paid"     numeric(12,2)            NOT NULL DEFAULT 0,
  "payment_status"  text                     NOT NULL DEFAULT 'unpaid'::text,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "supplier_invoices_organization_id_supplier_id_invoice_numbe_key" UNIQUE (organization_id, supplier_id, invoice_number),
  CONSTRAINT "supplier_invoices_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."supplier_invoices"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."supplier_payments" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id"     uuid                     NOT NULL,
  "supplier_invoice_id" uuid                     NOT NULL,
  "amount"              numeric(12,2)            NOT NULL,
  "payment_method"      text,
  "paid_by"             uuid,
  "paid_at"             timestamp with time zone NOT NULL DEFAULT now(),
  "created_at"          timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "supplier_payments_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."supplier_payments"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."suppliers" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "name"            text                     NOT NULL,
  "contact_name"    text,
  "phone"           text,
  "email"           text,
  "address"         text,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "suppliers_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."suppliers"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."whatsapp_conversations" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "organization_id" uuid                     NOT NULL,
  "customer_phone"  text                     NOT NULL,
  "branch_id"       uuid,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "whatsapp_conversations_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."whatsapp_conversations"
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."sale_line_items"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE "public"."sale_line_items"
  ALTER COLUMN "is_nhis" SET DEFAULT false;

ALTER TABLE "public"."sale_line_items"
  ALTER COLUMN "sold_as" SET DEFAULT 'unit'::text;

ALTER TABLE "public"."sales_transactions"
  ALTER COLUMN "created_at" SET DEFAULT now();

ALTER TABLE "public"."sales_transactions"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE "public"."sales_transactions"
  ALTER COLUMN "status" SET DEFAULT 'completed'::text;

ALTER TABLE "public"."stock_movements"
  ALTER COLUMN "created_at" SET DEFAULT now();

ALTER TABLE "public"."stock_movements"
  ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

CREATE OR REPLACE FUNCTION public.custom_access_token_hook (
  event jsonb
)
  RETURNS jsonb
  LANGUAGE plpgsql
  STABLE
  AS $function$
declare
  claims jsonb;
  v_org_id uuid;
begin
  select organization_id into v_org_id
  from staff
  where auth_user_id = (event ->> 'user_id')::uuid
  limit 1;

  claims := coalesce(event -> 'claims', '{}'::jsonb);

  if v_org_id is not null then
    claims := jsonb_set(claims, '{org_id}', to_jsonb(v_org_id::text));
  end if;

  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$function$;

ALTER TABLE "platform"."branch_installations"
  ADD CONSTRAINT "branch_installations_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."branch_devices"
  ADD CONSTRAINT "branch_devices_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."branch_products"
  ADD CONSTRAINT "branch_products_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_order_line_items"
  ADD CONSTRAINT "customer_order_line_items_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_orders"
  ADD CONSTRAINT "customer_orders_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_order_line_items"
  ADD CONSTRAINT "customer_order_line_items_customer_order_id_fkey" FOREIGN KEY (customer_order_id) REFERENCES public.customer_orders(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_insurance_memberships"
  ADD CONSTRAINT "customer_insurance_memberships_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;

ALTER TABLE "public"."insurance_medicine_price_history"
  ADD CONSTRAINT "insurance_medicine_price_hist_insurance_provider_medicine__fkey" FOREIGN KEY (insurance_provider_medicine_id) REFERENCES public.insurance_provider_medicines(id)
    ON DELETE CASCADE;

ALTER TABLE "public"."customer_insurance_memberships"
  ADD CONSTRAINT "customer_insurance_memberships_insurance_provider_id_fkey" FOREIGN KEY (insurance_provider_id) REFERENCES public.insurance_providers(id);

ALTER TABLE "public"."insurance_provider_medicines"
  ADD CONSTRAINT "insurance_provider_medicines_insurance_provider_id_fkey" FOREIGN KEY (insurance_provider_id) REFERENCES public.insurance_providers(id) ON DELETE CASCADE;

ALTER TABLE "public"."org_product_insurance_links"
  ADD CONSTRAINT "org_product_insurance_links_insurance_provider_medicine_id_fkey" FOREIGN KEY (insurance_provider_medicine_id) REFERENCES public.insurance_provider_medicines(id)
    ON DELETE CASCADE;

ALTER TABLE "public"."org_products"
  ADD CONSTRAINT "org_products_master_drug_id_fkey" FOREIGN KEY (master_drug_id) REFERENCES public.master_drug_catalog(id) ON DELETE SET NULL;

ALTER TABLE "public"."branch_products"
  ADD CONSTRAINT "branch_products_org_product_id_fkey" FOREIGN KEY (org_product_id) REFERENCES public.org_products(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_order_line_items"
  ADD CONSTRAINT "customer_order_line_items_org_product_id_fkey" FOREIGN KEY (org_product_id) REFERENCES public.org_products(id);

ALTER TABLE "public"."org_product_insurance_links"
  ADD CONSTRAINT "org_product_insurance_links_org_product_id_fkey" FOREIGN KEY (org_product_id) REFERENCES public.org_products(id) ON DELETE CASCADE;

ALTER TABLE "platform"."branch_installations"
  ADD CONSTRAINT "branch_installations_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "platform"."licenses"
  ADD CONSTRAINT "licenses_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "platform"."tenant_paystack_accounts"
  ADD CONSTRAINT "tenant_paystack_accounts_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."branch_devices"
  ADD CONSTRAINT "branch_devices_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."branch_products"
  ADD CONSTRAINT "branch_products_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."branches"
  ADD CONSTRAINT "branches_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_insurance_memberships"
  ADD CONSTRAINT "customer_insurance_memberships_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_order_line_items"
  ADD CONSTRAINT "customer_order_line_items_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_orders"
  ADD CONSTRAINT "customer_orders_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."customers"
  ADD CONSTRAINT "customers_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."insurance_providers"
  ADD CONSTRAINT "insurance_providers_created_by_organization_id_fkey" FOREIGN KEY (created_by_organization_id) REFERENCES public.organizations(id);

ALTER TABLE "public"."org_product_insurance_links"
  ADD CONSTRAINT "org_product_insurance_links_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."org_products"
  ADD CONSTRAINT "org_products_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."prescription_uploads"
  ADD CONSTRAINT "prescription_uploads_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_batches"
  ADD CONSTRAINT "product_batches_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_batches"
  ADD CONSTRAINT "product_batches_org_product_id_fkey" FOREIGN KEY (org_product_id) REFERENCES public.org_products(id) ON DELETE CASCADE;

ALTER TABLE "public"."product_batches"
  ADD CONSTRAINT "product_batches_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES public.customers(id);

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_insurance_provider_medicine_id_fkey" FOREIGN KEY (insurance_provider_medicine_id) REFERENCES public.insurance_provider_medicines(id);

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_org_product_id_fkey" FOREIGN KEY (org_product_id) REFERENCES public.org_products(id);

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_pkey" PRIMARY KEY (id, created_at);

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_product_batch_id_fkey" FOREIGN KEY (product_batch_id) REFERENCES public.product_batches(id);

ALTER TABLE "public"."sales_transactions"
  ADD CONSTRAINT "sales_transactions_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."sales_transactions"
  ADD CONSTRAINT "sales_transactions_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."sales_transactions"
  ADD CONSTRAINT "sales_transactions_pkey" PRIMARY KEY (id, created_at);

ALTER TABLE "public"."sale_line_items"
  ADD CONSTRAINT "sale_line_items_sales_transaction_id_created_at_fkey" FOREIGN KEY (sales_transaction_id, created_at) REFERENCES public.sales_transactions(id, created_at)
    ON DELETE CASCADE;

ALTER TABLE "public"."staff"
  ADD CONSTRAINT "staff_auth_user_id_fkey" FOREIGN KEY (auth_user_id) REFERENCES auth.users(id);

ALTER TABLE "public"."staff"
  ADD CONSTRAINT "staff_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_orders"
  ADD CONSTRAINT "customer_orders_cancelled_by_fkey" FOREIGN KEY (cancelled_by) REFERENCES public.staff(id);

ALTER TABLE "public"."customer_orders"
  ADD CONSTRAINT "customer_orders_refunded_by_fkey" FOREIGN KEY (refunded_by) REFERENCES public.staff(id);

ALTER TABLE "public"."prescription_uploads"
  ADD CONSTRAINT "prescription_uploads_reviewed_by_fkey" FOREIGN KEY (reviewed_by) REFERENCES public.staff(id);

ALTER TABLE "public"."sales_transactions"
  ADD CONSTRAINT "sales_transactions_cashier_id_fkey" FOREIGN KEY (cashier_id) REFERENCES public.staff(id);

ALTER TABLE "public"."staff_branch_roles"
  ADD CONSTRAINT "staff_branch_roles_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."staff_branch_roles"
  ADD CONSTRAINT "staff_branch_roles_granted_by_fkey" FOREIGN KEY (granted_by) REFERENCES public.staff(id);

ALTER TABLE "public"."staff_branch_roles"
  ADD CONSTRAINT "staff_branch_roles_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."staff_branch_roles"
  ADD CONSTRAINT "staff_branch_roles_role_id_fkey" FOREIGN KEY (role_id) REFERENCES public.roles(id);

ALTER TABLE "public"."staff_branch_roles"
  ADD CONSTRAINT "staff_branch_roles_staff_id_fkey" FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;

ALTER TABLE "public"."stock_movements"
  ADD CONSTRAINT "stock_movements_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."stock_movements"
  ADD CONSTRAINT "stock_movements_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.staff(id);

ALTER TABLE "public"."stock_movements"
  ADD CONSTRAINT "stock_movements_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."stock_movements"
  ADD CONSTRAINT "stock_movements_pkey" PRIMARY KEY (id, created_at);

ALTER TABLE "public"."stock_movements"
  ADD CONSTRAINT "stock_movements_product_batch_id_fkey" FOREIGN KEY (product_batch_id) REFERENCES public.product_batches(id);

ALTER TABLE "public"."stock_transfers"
  ADD CONSTRAINT "stock_transfers_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES public.staff(id);

ALTER TABLE "public"."stock_transfers"
  ADD CONSTRAINT "stock_transfers_from_branch_id_fkey" FOREIGN KEY (from_branch_id) REFERENCES public.branches(id);

ALTER TABLE "public"."stock_transfers"
  ADD CONSTRAINT "stock_transfers_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."stock_transfers"
  ADD CONSTRAINT "stock_transfers_requested_by_fkey" FOREIGN KEY (requested_by) REFERENCES public.staff(id);

ALTER TABLE "public"."stock_transfers"
  ADD CONSTRAINT "stock_transfers_to_branch_id_fkey" FOREIGN KEY (to_branch_id) REFERENCES public.branches(id);

ALTER TABLE "public"."supplier_invoice_line_items"
  ADD CONSTRAINT "supplier_invoice_line_items_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_invoice_line_items"
  ADD CONSTRAINT "supplier_invoice_line_items_org_product_id_fkey" FOREIGN KEY (org_product_id) REFERENCES public.org_products(id);

ALTER TABLE "public"."supplier_invoice_line_items"
  ADD CONSTRAINT "supplier_invoice_line_items_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_invoice_line_items"
  ADD CONSTRAINT "supplier_invoice_line_items_product_batch_id_fkey" FOREIGN KEY (product_batch_id) REFERENCES public.product_batches(id);

ALTER TABLE "public"."supplier_invoices"
  ADD CONSTRAINT "supplier_invoices_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_invoices"
  ADD CONSTRAINT "supplier_invoices_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_invoice_line_items"
  ADD CONSTRAINT "supplier_invoice_line_items_supplier_invoice_id_fkey" FOREIGN KEY (supplier_invoice_id) REFERENCES public.supplier_invoices(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_invoices"
  ADD CONSTRAINT "supplier_invoices_received_by_fkey" FOREIGN KEY (received_by) REFERENCES public.staff(id);

ALTER TABLE "public"."supplier_payments"
  ADD CONSTRAINT "supplier_payments_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_payments"
  ADD CONSTRAINT "supplier_payments_paid_by_fkey" FOREIGN KEY (paid_by) REFERENCES public.staff(id);

ALTER TABLE "public"."supplier_payments"
  ADD CONSTRAINT "supplier_payments_supplier_invoice_id_fkey" FOREIGN KEY (supplier_invoice_id) REFERENCES public.supplier_invoices(id) ON DELETE CASCADE;

ALTER TABLE "public"."suppliers"
  ADD CONSTRAINT "suppliers_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."supplier_invoices"
  ADD CONSTRAINT "supplier_invoices_supplier_id_fkey" FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);

ALTER TABLE "public"."whatsapp_conversations"
  ADD CONSTRAINT "whatsapp_conversations_branch_id_fkey" FOREIGN KEY (branch_id) REFERENCES public.branches(id);

ALTER TABLE "public"."whatsapp_conversations"
  ADD CONSTRAINT "whatsapp_conversations_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;

ALTER TABLE "public"."customer_orders"
  ADD CONSTRAINT "customer_orders_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES public.whatsapp_conversations(id);

ALTER TABLE "public"."prescription_uploads"
  ADD CONSTRAINT "prescription_uploads_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES public.whatsapp_conversations(id);

CREATE INDEX branch_installations_organization_id_branch_id_idx ON platform.branch_installations USING btree (organization_id, branch_id);

CREATE INDEX licenses_organization_id_idx ON platform.licenses USING btree (organization_id);

CREATE INDEX tenant_paystack_accounts_organization_id_idx ON platform.tenant_paystack_accounts USING btree (organization_id);

CREATE INDEX branch_devices_organization_id_branch_id_idx ON public.branch_devices USING btree (organization_id, branch_id);

CREATE INDEX branch_products_organization_id_branch_id_idx ON public.branch_products USING btree (organization_id, branch_id);

CREATE INDEX branches_organization_id_idx ON public.branches USING btree (organization_id);

CREATE INDEX customer_insurance_membership_organization_id_customer_id_i_idx ON public.customer_insurance_memberships
  USING btree (organization_id, customer_id, insurance_provider_id);

CREATE INDEX customer_order_line_items_organization_id_branch_id_custome_idx ON public.customer_order_line_items USING btree (organization_id, branch_id, customer_order_id);

CREATE INDEX customer_orders_organization_id_branch_id_created_at_idx ON public.customer_orders USING btree (organization_id, branch_id, created_at);

CREATE INDEX customers_organization_id_idx ON public.customers USING btree (organization_id);

CREATE INDEX insurance_medicine_price_hist_insurance_provider_medicine_i_idx ON public.insurance_medicine_price_history USING btree (insurance_provider_medicine_id, effective_date);

CREATE INDEX insurance_provider_medicines_insurance_provider_id_idx ON public.insurance_provider_medicines USING btree (insurance_provider_id);

CREATE INDEX org_product_insurance_links_organization_id_org_product_id__idx ON public.org_product_insurance_links
  USING btree (organization_id, org_product_id, insurance_provider_medicine_id);

CREATE INDEX org_products_organization_id_idx ON public.org_products USING btree (organization_id);

CREATE INDEX prescription_uploads_organization_id_conversation_id_idx ON public.prescription_uploads USING btree (organization_id, conversation_id);

CREATE INDEX product_batches_organization_id_branch_id_org_product_id_idx ON public.product_batches USING btree (organization_id, branch_id, org_product_id);

CREATE INDEX sale_line_items_organization_id_branch_id_created_at_idx1 ON ONLY public.sale_line_items USING btree (organization_id, branch_id, created_at)
  WHERE is_nhis;

CREATE INDEX sale_line_items_organization_id_branch_id_created_at_idx ON ONLY public.sale_line_items USING btree (organization_id, branch_id, created_at);

CREATE TABLE "public"."sale_line_items_2026_10" PARTITION OF "public"."sale_line_items" FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');

ALTER TABLE "public"."sale_line_items_2026_10"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX sales_transactions_organization_id_branch_id_created_at_idx ON ONLY public.sales_transactions USING btree (organization_id, branch_id, created_at);

CREATE TABLE "public"."sales_transactions_2026_10" PARTITION OF "public"."sales_transactions" FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');

ALTER TABLE "public"."sales_transactions_2026_10"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX staff_branch_roles_organization_id_branch_id_idx ON public.staff_branch_roles USING btree (organization_id, branch_id);

CREATE INDEX staff_organization_id_idx ON public.staff USING btree (organization_id);

CREATE INDEX stock_movements_organization_id_branch_id_created_at_idx ON ONLY public.stock_movements USING btree (organization_id, branch_id, created_at);

CREATE TABLE "public"."stock_movements_2026_10" PARTITION OF "public"."stock_movements" FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00');

ALTER TABLE "public"."stock_movements_2026_10"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX stock_transfers_organization_id_from_branch_id_to_branch_id_idx ON public.stock_transfers USING btree (organization_id, from_branch_id, to_branch_id);

CREATE INDEX supplier_invoice_line_items_organization_id_branch_id_suppl_idx ON public.supplier_invoice_line_items USING btree (organization_id, branch_id, supplier_invoice_id);

CREATE INDEX supplier_invoices_organization_id_branch_id_supplier_id_idx ON public.supplier_invoices USING btree (organization_id, branch_id, supplier_id);

CREATE INDEX supplier_payments_organization_id_supplier_invoice_id_idx ON public.supplier_payments USING btree (organization_id, supplier_invoice_id);

CREATE INDEX suppliers_organization_id_idx ON public.suppliers USING btree (organization_id);

CREATE INDEX whatsapp_conversations_organization_id_branch_id_idx ON public.whatsapp_conversations USING btree (organization_id, branch_id);

CREATE POLICY "read_all" ON "public"."insurance_provider_medicines"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "read_all" ON "public"."insurance_providers"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "read_all" ON "public"."master_drug_catalog"
  FOR SELECT
  TO PUBLIC
  USING (true);

CREATE POLICY "read_all" ON "public"."roles"
  FOR SELECT
  TO PUBLIC
  USING (true);

COMMENT ON EXTENSION "postgis" IS 'PostGIS geometry and geography spatial types and functions';

GRANT EXECUTE ON FUNCTION "public"."custom_access_token_hook"(jsonb) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."custom_access_token_hook"(jsonb) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."custom_access_token_hook"(jsonb) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."custom_access_token_hook"(jsonb) TO "service_role", "supabase_auth_admin";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branch_devices" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."branch_devices" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branch_devices" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branch_devices" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branch_products" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."branch_products" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branch_products" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branch_products" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branches" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."branches" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branches" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."branches" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_insurance_memberships" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."customer_insurance_memberships" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_insurance_memberships" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_insurance_memberships" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_order_line_items" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."customer_order_line_items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_order_line_items" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_order_line_items" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_orders" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."customer_orders" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_orders" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customer_orders" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customers" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."customers" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customers" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."customers" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_medicine_price_history" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."insurance_medicine_price_history" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_medicine_price_history" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_medicine_price_history" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_provider_medicines" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."insurance_provider_medicines" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_provider_medicines" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_provider_medicines" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_providers" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."insurance_providers" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_providers" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."insurance_providers" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."master_drug_catalog" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."master_drug_catalog" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."master_drug_catalog" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."master_drug_catalog" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."org_product_insurance_links" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."org_product_insurance_links" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."org_product_insurance_links" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."org_product_insurance_links" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."org_products" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."org_products" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."org_products" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."org_products" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."organizations" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."organizations" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."organizations" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."organizations" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."prescription_uploads" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."prescription_uploads" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."prescription_uploads" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."prescription_uploads" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_batches" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."product_batches" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_batches" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_batches" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."roles" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."roles" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."roles" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."roles" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sale_line_items" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."sale_line_items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sale_line_items" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sale_line_items" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sale_line_items_2026_10" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."sale_line_items_2026_10" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sale_line_items_2026_10" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sale_line_items_2026_10" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sales_transactions" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."sales_transactions" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sales_transactions" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sales_transactions" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sales_transactions_2026_10" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."sales_transactions_2026_10" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sales_transactions_2026_10" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."sales_transactions_2026_10" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."staff" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."staff" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."staff" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."staff" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."staff_branch_roles" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."staff_branch_roles" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."staff_branch_roles" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."staff_branch_roles" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_movements" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."stock_movements" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_movements" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_movements" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_movements_2026_10" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."stock_movements_2026_10" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_movements_2026_10" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_movements_2026_10" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_transfers" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."stock_transfers" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_transfers" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stock_transfers" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_invoice_line_items" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."supplier_invoice_line_items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_invoice_line_items" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_invoice_line_items" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_invoices" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."supplier_invoices" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_invoices" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_invoices" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_payments" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."supplier_payments" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_payments" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."supplier_payments" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."suppliers" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."suppliers" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."suppliers" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."suppliers" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."whatsapp_conversations" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."whatsapp_conversations" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."whatsapp_conversations" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."whatsapp_conversations" TO "service_role";
