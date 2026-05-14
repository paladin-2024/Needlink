drop extension if exists "pg_net";

drop trigger if exists "donation_needs_updated_at" on "public"."donation_needs";

drop trigger if exists "ngos_updated_at" on "public"."ngos";

drop trigger if exists "pledges_updated_at" on "public"."pledges";

drop trigger if exists "profiles_updated_at" on "public"."profiles";

drop policy "deliveries: authenticated read" on "public"."deliveries";

drop policy "deliveries: ngo insert" on "public"."deliveries";

drop policy "donation_needs: ngo delete" on "public"."donation_needs";

drop policy "donation_needs: ngo insert" on "public"."donation_needs";

drop policy "donation_needs: ngo update" on "public"."donation_needs";

drop policy "donation_needs: public read" on "public"."donation_needs";

drop policy "ngos: own insert" on "public"."ngos";

drop policy "ngos: own update" on "public"."ngos";

drop policy "ngos: public read" on "public"."ngos";

drop policy "pledges: donor insert" on "public"."pledges";

drop policy "pledges: donor read own" on "public"."pledges";

drop policy "pledges: ngo read own needs" on "public"."pledges";

drop policy "pledges: ngo update status" on "public"."pledges";

drop policy "profiles: authenticated read" on "public"."profiles";

drop policy "profiles: own update" on "public"."profiles";

revoke delete on table "public"."deliveries" from "anon";

revoke insert on table "public"."deliveries" from "anon";

revoke references on table "public"."deliveries" from "anon";

revoke select on table "public"."deliveries" from "anon";

revoke trigger on table "public"."deliveries" from "anon";

revoke truncate on table "public"."deliveries" from "anon";

revoke update on table "public"."deliveries" from "anon";

revoke delete on table "public"."deliveries" from "authenticated";

revoke insert on table "public"."deliveries" from "authenticated";

revoke references on table "public"."deliveries" from "authenticated";

revoke select on table "public"."deliveries" from "authenticated";

revoke trigger on table "public"."deliveries" from "authenticated";

revoke truncate on table "public"."deliveries" from "authenticated";

revoke update on table "public"."deliveries" from "authenticated";

revoke delete on table "public"."deliveries" from "service_role";

revoke insert on table "public"."deliveries" from "service_role";

revoke references on table "public"."deliveries" from "service_role";

revoke select on table "public"."deliveries" from "service_role";

revoke trigger on table "public"."deliveries" from "service_role";

revoke truncate on table "public"."deliveries" from "service_role";

revoke update on table "public"."deliveries" from "service_role";

revoke delete on table "public"."donation_needs" from "anon";

revoke insert on table "public"."donation_needs" from "anon";

revoke references on table "public"."donation_needs" from "anon";

revoke select on table "public"."donation_needs" from "anon";

revoke trigger on table "public"."donation_needs" from "anon";

revoke truncate on table "public"."donation_needs" from "anon";

revoke update on table "public"."donation_needs" from "anon";

revoke delete on table "public"."donation_needs" from "authenticated";

revoke insert on table "public"."donation_needs" from "authenticated";

revoke references on table "public"."donation_needs" from "authenticated";

revoke select on table "public"."donation_needs" from "authenticated";

revoke trigger on table "public"."donation_needs" from "authenticated";

revoke truncate on table "public"."donation_needs" from "authenticated";

revoke update on table "public"."donation_needs" from "authenticated";

revoke delete on table "public"."donation_needs" from "service_role";

revoke insert on table "public"."donation_needs" from "service_role";

revoke references on table "public"."donation_needs" from "service_role";

revoke select on table "public"."donation_needs" from "service_role";

revoke trigger on table "public"."donation_needs" from "service_role";

revoke truncate on table "public"."donation_needs" from "service_role";

revoke update on table "public"."donation_needs" from "service_role";

revoke delete on table "public"."ngos" from "anon";

revoke insert on table "public"."ngos" from "anon";

revoke references on table "public"."ngos" from "anon";

revoke select on table "public"."ngos" from "anon";

revoke trigger on table "public"."ngos" from "anon";

revoke truncate on table "public"."ngos" from "anon";

revoke update on table "public"."ngos" from "anon";

revoke delete on table "public"."ngos" from "authenticated";

revoke insert on table "public"."ngos" from "authenticated";

revoke references on table "public"."ngos" from "authenticated";

revoke select on table "public"."ngos" from "authenticated";

revoke trigger on table "public"."ngos" from "authenticated";

revoke truncate on table "public"."ngos" from "authenticated";

revoke update on table "public"."ngos" from "authenticated";

revoke delete on table "public"."ngos" from "service_role";

revoke insert on table "public"."ngos" from "service_role";

revoke references on table "public"."ngos" from "service_role";

revoke select on table "public"."ngos" from "service_role";

revoke trigger on table "public"."ngos" from "service_role";

revoke truncate on table "public"."ngos" from "service_role";

revoke update on table "public"."ngos" from "service_role";

revoke delete on table "public"."pledges" from "anon";

revoke insert on table "public"."pledges" from "anon";

revoke references on table "public"."pledges" from "anon";

revoke select on table "public"."pledges" from "anon";

revoke trigger on table "public"."pledges" from "anon";

revoke truncate on table "public"."pledges" from "anon";

revoke update on table "public"."pledges" from "anon";

revoke delete on table "public"."pledges" from "authenticated";

revoke insert on table "public"."pledges" from "authenticated";

revoke references on table "public"."pledges" from "authenticated";

revoke select on table "public"."pledges" from "authenticated";

revoke trigger on table "public"."pledges" from "authenticated";

revoke truncate on table "public"."pledges" from "authenticated";

revoke update on table "public"."pledges" from "authenticated";

revoke delete on table "public"."pledges" from "service_role";

revoke insert on table "public"."pledges" from "service_role";

revoke references on table "public"."pledges" from "service_role";

revoke select on table "public"."pledges" from "service_role";

revoke trigger on table "public"."pledges" from "service_role";

revoke truncate on table "public"."pledges" from "service_role";

revoke update on table "public"."pledges" from "service_role";

revoke delete on table "public"."profiles" from "anon";

revoke insert on table "public"."profiles" from "anon";

revoke references on table "public"."profiles" from "anon";

revoke select on table "public"."profiles" from "anon";

revoke trigger on table "public"."profiles" from "anon";

revoke truncate on table "public"."profiles" from "anon";

revoke update on table "public"."profiles" from "anon";

revoke delete on table "public"."profiles" from "authenticated";

revoke insert on table "public"."profiles" from "authenticated";

revoke references on table "public"."profiles" from "authenticated";

revoke select on table "public"."profiles" from "authenticated";

revoke trigger on table "public"."profiles" from "authenticated";

revoke truncate on table "public"."profiles" from "authenticated";

revoke update on table "public"."profiles" from "authenticated";

revoke delete on table "public"."profiles" from "service_role";

revoke insert on table "public"."profiles" from "service_role";

revoke references on table "public"."profiles" from "service_role";

revoke select on table "public"."profiles" from "service_role";

revoke trigger on table "public"."profiles" from "service_role";

revoke truncate on table "public"."profiles" from "service_role";

revoke update on table "public"."profiles" from "service_role";

alter table "public"."deliveries" drop constraint "deliveries_confirmed_by_fkey";

alter table "public"."deliveries" drop constraint "deliveries_pledge_id_fkey";

alter table "public"."deliveries" drop constraint "deliveries_pledge_id_key";

alter table "public"."donation_needs" drop constraint "donation_needs_ngo_id_fkey";

alter table "public"."donation_needs" drop constraint "donation_needs_quantity_needed_check";

alter table "public"."donation_needs" drop constraint "donation_needs_quantity_pledged_check";

alter table "public"."ngos" drop constraint "ngos_admin_id_fkey";

alter table "public"."ngos" drop constraint "ngos_admin_id_key";

alter table "public"."pledges" drop constraint "pledges_donor_id_fkey";

alter table "public"."pledges" drop constraint "pledges_need_id_fkey";

alter table "public"."pledges" drop constraint "pledges_quantity_check";

alter table "public"."profiles" drop constraint "profiles_id_fkey";

drop function if exists "public"."handle_new_user"();

drop function if exists "public"."set_updated_at"();

alter table "public"."deliveries" drop constraint "deliveries_pkey";

alter table "public"."donation_needs" drop constraint "donation_needs_pkey";

alter table "public"."ngos" drop constraint "ngos_pkey";

alter table "public"."pledges" drop constraint "pledges_pkey";

alter table "public"."profiles" drop constraint "profiles_pkey";

drop index if exists "public"."deliveries_pkey";

drop index if exists "public"."deliveries_pledge_id_idx";

drop index if exists "public"."deliveries_pledge_id_key";

drop index if exists "public"."donation_needs_category_idx";

drop index if exists "public"."donation_needs_deadline_idx";

drop index if exists "public"."donation_needs_ngo_id_idx";

drop index if exists "public"."donation_needs_pkey";

drop index if exists "public"."donation_needs_status_idx";

drop index if exists "public"."ngos_admin_id_idx";

drop index if exists "public"."ngos_admin_id_key";

drop index if exists "public"."ngos_pkey";

drop index if exists "public"."pledges_donor_id_idx";

drop index if exists "public"."pledges_need_id_idx";

drop index if exists "public"."pledges_pkey";

drop index if exists "public"."pledges_status_idx";

drop index if exists "public"."profiles_pkey";

drop table "public"."deliveries";

drop table "public"."donation_needs";

drop table "public"."ngos";

drop table "public"."pledges";

drop table "public"."profiles";

drop type "public"."item_category";

drop type "public"."need_status";

drop type "public"."pledge_status";

drop type "public"."urgency_level";

drop type "public"."user_role";

drop trigger if exists "on_auth_user_created" on "auth"."users";


