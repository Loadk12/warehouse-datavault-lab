begin;
update lab08_3nf.service_order set status_id=3 where order_no='O001';
insert into lab08_3nf.payment values (25, 'P025', 1, '2026-11-22 11:00:00+03', 1200.0, 'card');
commit;
