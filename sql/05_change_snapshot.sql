-- Second snapshot: the source now has a different phone and order status.
begin;
update lab08_3nf.customer set phone='+70000000991' where customer_code='C001';
update lab08_3nf.service_order set status_id=2 where order_no='O001';
commit;
