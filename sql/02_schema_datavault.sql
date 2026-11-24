-- Classic hub / link / satellite model. Hash keys use md5 for reproducibility, not security.

create table lab08_dv.h_customer (
    customer_hk char(32) primary key,
    customer_code varchar(20) not null unique,
    load_dts timestamptz not null, record_source text not null
);
create table lab08_dv.s_customer (
    customer_hk char(32) not null references lab08_dv.h_customer,
    load_dts timestamptz not null, record_source text not null,
    hashdiff char(32) not null, full_name text not null, phone text not null,
    primary key (customer_hk, load_dts)
);

create table lab08_dv.h_employee (
    employee_hk char(32) primary key,
    employee_code varchar(20) not null unique,
    load_dts timestamptz not null, record_source text not null
);
create table lab08_dv.s_employee (
    employee_hk char(32) not null references lab08_dv.h_employee,
    load_dts timestamptz not null, record_source text not null,
    hashdiff char(32) not null, full_name text not null, specialization text not null,
    primary key (employee_hk, load_dts)
);

create table lab08_dv.h_service (
    service_hk char(32) primary key,
    service_code varchar(20) not null unique,
    load_dts timestamptz not null, record_source text not null
);
create table lab08_dv.s_service (
    service_hk char(32) not null references lab08_dv.h_service,
    load_dts timestamptz not null, record_source text not null,
    hashdiff char(32) not null, service_name text not null, base_price numeric(12,2) not null check (base_price >= 0),
    primary key (service_hk, load_dts)
);

create table lab08_dv.h_order (
    order_hk char(32) primary key,
    order_no varchar(20) not null unique,
    load_dts timestamptz not null, record_source text not null
);
create table lab08_dv.s_order (
    order_hk char(32) not null references lab08_dv.h_order,
    load_dts timestamptz not null, record_source text not null,
    hashdiff char(32) not null, created_at timestamptz not null, due_at timestamptz not null, status_code text not null,
    primary key (order_hk, load_dts)
);

create table lab08_dv.h_payment (
    payment_hk char(32) primary key,
    payment_no varchar(20) not null unique,
    load_dts timestamptz not null, record_source text not null
);
create table lab08_dv.s_payment (
    payment_hk char(32) not null references lab08_dv.h_payment,
    load_dts timestamptz not null, record_source text not null,
    hashdiff char(32) not null, paid_at timestamptz not null, amount numeric(12,2) not null check (amount > 0), method text not null,
    primary key (payment_hk, load_dts)
);

create table lab08_dv.l_order_customer (
    link_hk char(32) primary key,
    order_hk char(32) not null references lab08_dv.h_order,
    customer_hk char(32) not null references lab08_dv.h_customer,
    load_dts timestamptz not null, record_source text not null,
    unique (order_hk, customer_hk)
);
-- Grain is one immutable numbered order line and its service / performer.
create table lab08_dv.l_order_item (
    link_hk char(32) primary key,
    order_hk char(32) not null references lab08_dv.h_order,
    service_hk char(32) not null references lab08_dv.h_service,
    employee_hk char(32) not null references lab08_dv.h_employee,
    line_no integer not null check (line_no > 0),
    load_dts timestamptz not null, record_source text not null,
    unique (order_hk, line_no)
);
create table lab08_dv.s_order_item (
    link_hk char(32) not null references lab08_dv.l_order_item,
    load_dts timestamptz not null, record_source text not null,
    hashdiff char(32) not null,
    quantity integer not null check (quantity > 0),
    agreed_price numeric(12,2) not null check (agreed_price >= 0),
    primary key (link_hk, load_dts)
);
create table lab08_dv.l_order_payment (
    link_hk char(32) primary key,
    order_hk char(32) not null references lab08_dv.h_order,
    payment_hk char(32) not null references lab08_dv.h_payment,
    load_dts timestamptz not null, record_source text not null,
    unique (order_hk, payment_hk)
);
