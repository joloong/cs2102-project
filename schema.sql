-- CS2102 Project Team 41 schema.sql

CREATE TABLE IF NOT EXISTS Employees (
    eid char(20) primary key,
    name text not null,
    phone text not null,
    email text not null,
    join_date date not null,
    address text not null,
    depart_date date

    constraint valid_join_depart_date check ((depart_date - join_date) >= 0);
);
