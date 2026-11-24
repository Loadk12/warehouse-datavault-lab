-- One serialized snapshot loader. Replaying an unchanged snapshot is idempotent.

begin;

set local timezone to 'UTC';

select pg_advisory_xact_lock(12241,8);

select set_config('lab.load_dts', :'load_dts', false);

insert into lab08_dv.h_customer
select md5('crm:customer:' || customer_code), customer_code, current_setting('lab.load_dts')::timestamptz, 'crm_demo' from lab08_3nf.customer x
on conflict (customer_code) do nothing;

with incoming as (
    select md5('crm:customer:' || customer_code) as hk, md5(length(cast(full_name as text))::text || ':' || cast(full_name as text) || length(cast(phone as text))::text || ':' || cast(phone as text)) as hd, full_name, phone from lab08_3nf.customer x
)
insert into lab08_dv.s_customer
select i.hk, current_setting('lab.load_dts')::timestamptz, 'crm_demo', i.hd, i.full_name, i.phone
from incoming i
where i.hd is distinct from (
    select s.hashdiff from lab08_dv.s_customer s
    where s.customer_hk = i.hk order by s.load_dts desc limit 1
);

insert into lab08_dv.h_employee
select md5('crm:employee:' || employee_code), employee_code, current_setting('lab.load_dts')::timestamptz, 'crm_demo' from lab08_3nf.employee x
on conflict (employee_code) do nothing;

with incoming as (
    select md5('crm:employee:' || employee_code) as hk, md5(length(cast(full_name as text))::text || ':' || cast(full_name as text) || length(cast(specialization as text))::text || ':' || cast(specialization as text)) as hd, full_name, specialization from lab08_3nf.employee x
)
insert into lab08_dv.s_employee
select i.hk, current_setting('lab.load_dts')::timestamptz, 'crm_demo', i.hd, i.full_name, i.specialization
from incoming i
where i.hd is distinct from (
    select s.hashdiff from lab08_dv.s_employee s
    where s.employee_hk = i.hk order by s.load_dts desc limit 1
);

insert into lab08_dv.h_service
select md5('crm:service:' || service_code), service_code, current_setting('lab.load_dts')::timestamptz, 'crm_demo' from lab08_3nf.service x
on conflict (service_code) do nothing;

with incoming as (
    select md5('crm:service:' || service_code) as hk, md5(length(cast(service_name as text))::text || ':' || cast(service_name as text) || length(cast(base_price as text))::text || ':' || cast(base_price as text)) as hd, service_name, base_price from lab08_3nf.service x
)
insert into lab08_dv.s_service
select i.hk, current_setting('lab.load_dts')::timestamptz, 'crm_demo', i.hd, i.service_name, i.base_price
from incoming i
where i.hd is distinct from (
    select s.hashdiff from lab08_dv.s_service s
    where s.service_hk = i.hk order by s.load_dts desc limit 1
);

insert into lab08_dv.h_order
select md5('crm:order:' || order_no), order_no, current_setting('lab.load_dts')::timestamptz, 'crm_demo' from (select o.order_no, o.created_at, o.due_at, s.status_code from lab08_3nf.service_order o join lab08_3nf.order_status s using(status_id)) x
on conflict (order_no) do nothing;

with incoming as (
    select md5('crm:order:' || order_no) as hk, md5(length(cast(created_at as text))::text || ':' || cast(created_at as text) || length(cast(due_at as text))::text || ':' || cast(due_at as text) || length(cast(status_code as text))::text || ':' || cast(status_code as text)) as hd, created_at, due_at, status_code from (select o.order_no, o.created_at, o.due_at, s.status_code from lab08_3nf.service_order o join lab08_3nf.order_status s using(status_id)) x
)
insert into lab08_dv.s_order
select i.hk, current_setting('lab.load_dts')::timestamptz, 'crm_demo', i.hd, i.created_at, i.due_at, i.status_code
from incoming i
where i.hd is distinct from (
    select s.hashdiff from lab08_dv.s_order s
    where s.order_hk = i.hk order by s.load_dts desc limit 1
);

insert into lab08_dv.h_payment
select md5('crm:payment:' || payment_no), payment_no, current_setting('lab.load_dts')::timestamptz, 'crm_demo' from lab08_3nf.payment x
on conflict (payment_no) do nothing;

with incoming as (
    select md5('crm:payment:' || payment_no) as hk, md5(length(cast(paid_at as text))::text || ':' || cast(paid_at as text) || length(cast(amount as text))::text || ':' || cast(amount as text) || length(cast(method as text))::text || ':' || cast(method as text)) as hd, paid_at, amount, method from lab08_3nf.payment x
)
insert into lab08_dv.s_payment
select i.hk, current_setting('lab.load_dts')::timestamptz, 'crm_demo', i.hd, i.paid_at, i.amount, i.method
from incoming i
where i.hd is distinct from (
    select s.hashdiff from lab08_dv.s_payment s
    where s.payment_hk = i.hk order by s.load_dts desc limit 1
);

insert into lab08_dv.l_order_customer
select md5(md5('crm:order:' || o.order_no) || md5('crm:customer:' || c.customer_code)), md5('crm:order:' || o.order_no), md5('crm:customer:' || c.customer_code), current_setting('lab.load_dts')::timestamptz, 'crm_demo'
from lab08_3nf.service_order o join lab08_3nf.customer c using(customer_id)
on conflict do nothing;

insert into lab08_dv.l_order_item
select md5(md5('crm:order:' || o.order_no) || ':' || i.line_no::text), md5('crm:order:' || o.order_no), md5('crm:service:' || s.service_code), md5('crm:employee:' || e.employee_code),
    i.line_no, current_setting('lab.load_dts')::timestamptz, 'crm_demo'
from lab08_3nf.order_item i
join lab08_3nf.service_order o using(order_id)
join lab08_3nf.service s using(service_id)
join lab08_3nf.employee e using(employee_id)
on conflict do nothing;

with incoming as (
    select md5(md5('crm:order:' || o.order_no) || ':' || i.line_no::text) as hk, md5(i.quantity::text || ':' || i.agreed_price::text) as hd,
        i.quantity, i.agreed_price from lab08_3nf.order_item i
join lab08_3nf.service_order o using(order_id)
join lab08_3nf.service s using(service_id)
join lab08_3nf.employee e using(employee_id)
)
insert into lab08_dv.s_order_item
select i.hk, current_setting('lab.load_dts')::timestamptz, 'crm_demo', i.hd, i.quantity, i.agreed_price from incoming i
where i.hd is distinct from (
    select s.hashdiff from lab08_dv.s_order_item s where s.link_hk=i.hk
    order by s.load_dts desc limit 1
);

insert into lab08_dv.l_order_payment
select md5(md5('crm:order:' || o.order_no) || md5('crm:payment:' || p.payment_no)), md5('crm:order:' || o.order_no), md5('crm:payment:' || p.payment_no), current_setting('lab.load_dts')::timestamptz, 'crm_demo'
from lab08_3nf.payment p join lab08_3nf.service_order o using(order_id)
on conflict do nothing;
commit;
