-- CS2102 Project Team 41 schema.sql

CREATE TABLE IF NOT EXISTS Employees (
    eid char(20)    primary key,
    name            text not null,
    phone           text not null,
    email           text not null,
    join_date       date not null,
    address         text not null,
    depart_date     date

    constraint valid_join_depart_date check (
        (depart_date IS NULL) OR ((depart_date - join_date) >= 0)
    )
);

CREATE TABLE IF NOT EXISTS Part_time_Emp (
    eid         char(20) primary key references Employees
                on delete cascade,
    hourly_rate integer not null

    constraint valid_hourly_rate check ( hourly_rate >= 0)
);

CREATE TABLE IF NOT EXISTS Full_time_Emp (
    eid             char(20) primary key references Employees
                    on delete cascade,
    monthly_rate    integer not null

    constraint valid_monthly_rate check ( monthly_rate >= 0)
);

CREATE TABLE IF NOT EXISTS Instructors (
    eid             char(20) primary key references Employees
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Part_time_instructors (
    -- Part_time_employees must be Part_time_instructors
    eid             char(20) primary key references Part_time_instructors
                    on delete cascade           
);

CREATE TABLE IF NOT EXISTS Full_time_instructors (
    eid             char(20) primary key references Instructors
                    on delete cascade,
);

CREATE TABLE IF NOT EXISTS Administrators (
    eid             char(20) primary key references Instructors
                    on delete cascade,
);

CREATE TABLE IF NOT EXISTS Managers (
    eid             char(20) primary key references Instructors
                    on delete cascade,
);

CREATE TABLE IF NOT EXISTS Pay_slips (
    payment_date    date,
    amount          integer not null default 0,
    num_work_hours  integer,
    num_work_days   integer,
    primary key     (payment_date, eid),
    foreign key     (eid) references Employees
                    on delete cascade
    
    constraint non_negative_amount check (amount >= 0)
    constraint valid_num_work_hours check (
        (num_work_hours IS NULL) OR (num_work_hours >= 0)
    )
    constraint valid_num_work_days check (
        (num_work_days IS NULL) OR (num_work_days >= 0)
    )
);

CREATE TABLE IF NOT EXISTS Customers (
    cust_id     char(20)    primary key,
    phone       text        not null,
    name        text        not null,
    email       text        not null,
    address     text        not null
);

CREATE TABLE IF NOT EXISTS Credit_cards (
    cc_number   char(20)    primary key,
    CVV         integer     not null,
    expiry_date date        not null
);

CREATE TABLE IF NOT EXISTS Owns (
    cc_number   char(20)    primary key references Credit_cards,
    cust_id     char(20)    not null,
    from_date   date        not null,

    foreign key (cust_id) references Customers(cust_id)
);

CREATE TABLE IF NOT EXISTS Course_packages (
    package_id              char(20)    primary key,
    name                    text        not null,
    price                   integer     not null,
    num_free_registrations  integer     not null,
    sale_start_date         date        not null,
    sale_end_date           date        not null,

    constraint start_lte_end_date check (
        sale_start_date <= sale_end_date
    )
);
