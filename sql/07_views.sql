create view lab08_dv.v_customer_current as
select distinct on (customer_hk) * from lab08_dv.s_customer
order by customer_hk, load_dts desc;

create view lab08_dv.v_employee_current as
select distinct on (employee_hk) * from lab08_dv.s_employee
order by employee_hk, load_dts desc;

create view lab08_dv.v_service_current as
select distinct on (service_hk) * from lab08_dv.s_service
order by service_hk, load_dts desc;

create view lab08_dv.v_order_current as
select distinct on (order_hk) * from lab08_dv.s_order
order by order_hk, load_dts desc;

create view lab08_dv.v_payment_current as
select distinct on (payment_hk) * from lab08_dv.s_payment
order by payment_hk, load_dts desc;

create view lab08_dv.v_item_current as
select distinct on (link_hk) * from lab08_dv.s_order_item
order by link_hk, load_dts desc;
-- Aggregate independent many-to-one branches before joining to avoid fan-out.
create view lab08_dv.v_order_summary as
with costs as (
    select l.order_hk, sum(s.quantity*s.agreed_price) as order_amount
    from lab08_dv.l_order_item l join lab08_dv.v_item_current s using(link_hk)
    group by l.order_hk
), paid as (
    select l.order_hk, sum(s.amount) as paid_amount
    from lab08_dv.l_order_payment l join lab08_dv.v_payment_current s using(payment_hk)
    group by l.order_hk
)
select h.order_no, o.status_code, costs.order_amount,
    coalesce(paid.paid_amount,0) as paid_amount,
    costs.order_amount-coalesce(paid.paid_amount,0) as debt
from lab08_dv.h_order h
join lab08_dv.v_order_current o using(order_hk)
join costs using(order_hk) left join paid using(order_hk);
