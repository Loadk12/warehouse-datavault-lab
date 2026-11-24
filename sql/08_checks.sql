-- Raises an error if any invariant fails; run with psql -v ON_ERROR_STOP=1.
do $$
begin
    assert (select count(*) from lab08_dv.h_order)=24, '24 order hubs';
    assert (select count(*) from lab08_dv.h_customer)=6, '6 customer hubs';
    assert (select count(*) from lab08_dv.l_order_item)=48, '48 line links';
    assert (select count(*) from lab08_dv.s_order_item)=48, 'no duplicate line snapshots';
    assert (select count(*) from lab08_dv.h_payment)=25, '25 payment hubs';
    assert (select count(*) from lab08_dv.s_customer)=7, 'one phone change retained';
    assert (select count(*) from lab08_dv.s_order)=26, 'two status changes retained';
    assert (select string_agg(s.status_code,',' order by s.load_dts)
        from lab08_dv.s_order s join lab08_dv.h_order h using(order_hk)
        where h.order_no='O001')='new,in_progress,completed', 'order history';
    assert (select debt from lab08_dv.v_order_summary where order_no='O001')=0,
        'partial payments combined without fan-out';
    assert not exists (
        with expected as (
            select o.order_no, sum(i.quantity*i.agreed_price) as amount
            from lab08_3nf.service_order o join lab08_3nf.order_item i using(order_id)
            group by o.order_no
        )
        select 1 from expected e join lab08_dv.v_order_summary v using(order_no)
        where e.amount<>v.order_amount
    ), '3NF and vault totals agree for every order';
end $$;
select 'all invariants passed' as result;
