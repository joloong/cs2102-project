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

CREATE TABLE IF NOT EXISTS Pay_slips (
    payment_date    date,
    amount          integer default 0,
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