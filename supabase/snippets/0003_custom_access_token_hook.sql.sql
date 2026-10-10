create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
as $$
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
$$;

grant execute on function public.custom_access_token_hook to supabase_auth_admin;
