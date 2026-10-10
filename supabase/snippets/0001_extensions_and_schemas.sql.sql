create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists postgis;    -- branches.location, nearest-branch lookup

create schema if not exists platform;      -- founder-only data; never exposed through tenant RLS
