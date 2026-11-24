-- PostgreSQL. Isolated schemas for this lab; existing objects are never dropped.
create schema lab08_3nf;
create schema lab08_dv;
create table lab08_3nf.customer (
    customer_id integer primary key, customer_code varchar(20) not null unique,
    full_name text not null, phone varchar(30) not null
);
create table lab08_3nf.employee (
    employee_id integer primary key, employee_code varchar(20) not null unique,
    full_name text not null, specialization text not null
);
create table lab08_3nf.service (
    service_id integer primary key, service_code varchar(20) not null unique,
    service_name text not null, base_price numeric(12,2) not null check (base_price >= 0)
);
create table lab08_3nf.order_status (
    status_id integer primary key, status_code varchar(20) not null unique,
    status_name text not null
);
create table lab08_3nf.service_order (
    order_id integer primary key, order_no varchar(20) not null unique,
    customer_id integer not null references lab08_3nf.customer,
    created_at timestamptz not null, due_at timestamptz not null,
    status_id integer not null references lab08_3nf.order_status,
    check (due_at >= created_at)
);
-- Grain: one numbered service line within an order. The agreed price is historical.
create table lab08_3nf.order_item (
    order_id integer not null references lab08_3nf.service_order,
    line_no integer not null check (line_no > 0),
    service_id integer not null references lab08_3nf.service,
    employee_id integer not null references lab08_3nf.employee,
    quantity integer not null check (quantity > 0),
    agreed_price numeric(12,2) not null check (agreed_price >= 0),
    primary key (order_id, line_no)
);
create table lab08_3nf.payment (
    payment_id integer primary key, payment_no varchar(20) not null unique,
    order_id integer not null references lab08_3nf.service_order,
    paid_at timestamptz not null, amount numeric(12,2) not null check (amount > 0),
    method varchar(10) not null check (method in ('card', 'cash'))
);
create index ix_order_customer on lab08_3nf.service_order(customer_id);
create index ix_item_service on lab08_3nf.order_item(service_id);
create index ix_item_employee on lab08_3nf.order_item(employee_id);
create index ix_payment_order on lab08_3nf.payment(order_id);
