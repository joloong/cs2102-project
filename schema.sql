-- CS2102 Project Team 41 schema.sql

/*
CONSTRAINT THAT CANNOT BE COVERED:
    - If user registers/redeems the same session that he cancelled.
*/ 

DROP TABLE IF EXISTS Part_time_Emp CASCADE;
DROP TABLE IF EXISTS Employees CASCADE;
DROP TABLE IF EXISTS Full_time_Emp CASCADE;
DROP TABLE IF EXISTS Instructors CASCADE;
DROP TABLE IF EXISTS Part_time_instructors CASCADE;
DROP TABLE IF EXISTS Full_time_instructors CASCADE;
DROP TABLE IF EXISTS Administrators CASCADE;
DROP TABLE IF EXISTS Managers CASCADE;
DROP TABLE IF EXISTS Course_areas CASCADE;
DROP TABLE IF EXISTS Pay_slips CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Credit_cards CASCADE;
DROP TABLE IF EXISTS Owns CASCADE;
DROP TABLE IF EXISTS Course_packages CASCADE;
DROP TABLE IF EXISTS Buys CASCADE;
DROP TABLE IF EXISTS Courses CASCADE;
DROP TABLE IF EXISTS Offerings CASCADE;
DROP TABLE IF EXISTS Sessions CASCADE;
DROP TABLE IF EXISTS Registers CASCADE;
DROP TABLE IF EXISTS Redeems CASCADE;
DROP TABLE IF EXISTS Rooms CASCADE;
DROP TABLE IF EXISTS Cancels CASCADE;
DROP TABLE IF EXISTS Specializes CASCADE;

CREATE TABLE IF NOT EXISTS Employees (
    eid             SERIAL primary key,
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
    eid         integer primary key references Employees
                on delete cascade,
    hourly_rate integer not null

    constraint valid_hourly_rate check ( hourly_rate >= 0)
);

CREATE TABLE IF NOT EXISTS Full_time_Emp (
    eid             integer primary key references Employees
                    on delete cascade,
    monthly_rate    integer not null

    constraint valid_monthly_rate check (monthly_rate >= 0)
);

CREATE TABLE IF NOT EXISTS Managers (
    eid             integer primary key references Full_time_Emp
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Course_areas (
    area    text primary key,
    eid     integer not null,

    foreign key (eid) references Managers (eid)
);

CREATE TABLE IF NOT EXISTS Instructors (
    eid     integer     primary key references Employees
                        on delete cascade
    -- area    text        not null,

    -- foreign key (area) references Course_areas (area)
);

CREATE TABLE IF NOT EXISTS Part_time_instructors (
    eid             integer primary key references Part_time_Emp references Instructors
                    on delete cascade           
);

CREATE TABLE IF NOT EXISTS Full_time_instructors (
    eid             integer primary key references Full_time_Emp references Instructors
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Specializes (
    eid             integer references Instructors,
    area            text references Course_areas,
    primary key (eid, area)
);

CREATE TABLE IF NOT EXISTS Administrators (
    eid             integer primary key references Full_time_Emp
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Pay_slips (
    eid             integer,
    payment_date    date,
    amount          integer not null default 0,
    num_work_hours  integer,
    num_work_days   integer,
	
    primary key     (payment_date, eid),
    foreign key     (eid) references Employees
                    on delete cascade,
    
    constraint non_negative_amount check (amount >= 0),
    constraint valid_num_work_hours check (
        (num_work_hours IS NULL) OR (num_work_hours >= 0)
    ),
    constraint valid_num_work_days check (
        (num_work_days IS NULL) OR (num_work_days >= 0)
    )
);

CREATE TABLE IF NOT EXISTS Customers (
    cust_id     serial      primary key,
    phone       text        not null,
    cust_name   text        not null,
    email       text        not null,
    address     text        not null
);

CREATE TABLE IF NOT EXISTS Credit_cards (
    cc_number   char(20)    primary key,
    cvv         integer     not null,
    expiry_date date        not null
);

CREATE TABLE IF NOT EXISTS Owns (
    cc_number   char(20)    primary key references Credit_cards,
    cust_id     integer     not null,
    from_date   date        not null,

    foreign key (cust_id) references Customers(cust_id)
);

CREATE TABLE IF NOT EXISTS Course_packages (
    package_id              SERIAL      primary key,
    package_name            text        not null,
    price                   integer     not null,
    num_free_registrations  integer     not null,
    sale_start_date         date        not null,
    sale_end_date           date        not null,

    constraint min_price check (
        price >= 0
    ),
    constraint min_num_free_registrations check (
        num_free_registrations >= 0
    ),
    constraint start_lte_end_date check (
        sale_start_date <= sale_end_date
    )
);

CREATE TABLE IF NOT EXISTS Buys (
    transaction_date            date,
    cc_number                   char(20),
    package_id                  integer,
    num_remaining_registrations integer not null,

    primary key (transaction_date, cc_number, package_id),
    foreign key (cc_number) references Owns(cc_number),
    foreign key (package_id) references Course_packages(package_id),

    constraint min_num_remaining_registrations check (
        num_remaining_registrations >= 0
    )
);

CREATE TABLE IF NOT EXISTS Courses (
    course_id   SERIAL      primary key,
    title       text        not null,
    duration    integer     not null,
    area        text        not null,
    description text,

    foreign key (area) references Course_areas (area)
);

CREATE TABLE IF NOT EXISTS Offerings (
    course_id                   integer,
    launch_date                 date,
    start_date                  date        not null,
    end_date                    date        not null,
    registration_deadline       date        not null,
    fees                        integer     not null,
    seating_capacity            integer     not null,
    target_number_registrations integer     not null,
    eid                         integer     not null,
	
    primary key	(launch_date, course_id),
    foreign key	(course_id) references Courses,
    foreign key (eid) references Administrators,
	
    constraint within_capacity check (
        target_number_registrations <= seating_capacity
    ),
    constraint end_lte_start_date check (
        start_date <= end_date
    ),
    constraint register_lte_launch_date check (
        launch_date <= registration_deadline
    ),
    constraint start_lte_launch_date check (
        launch_date <= start_date
    )
);

CREATE TABLE IF NOT EXISTS Rooms (
    rid                 SERIAL,
    seating_capacity    integer     not null,
    location            text        not null,

    primary key (rid),


    constraint valid_max_seating_capacity check (
        seating_capacity > 0
    )
);

CREATE TABLE IF NOT EXISTS Sessions (
    sid             integer,
    course_id       integer,
    launch_date     date,
    session_date    date        not null,
    start_time      integer     not null,
    end_time        integer     not null,
    rid             integer     not null,
    eid             integer     not null,

    primary key (sid, course_id, launch_date),
    foreign key (launch_date, course_id) references Offerings,
    foreign key (rid) references Rooms,
    foreign key (eid) references Instructors,

    constraint end_lte_start_time check (
        start_time <= end_time
    ),
    constraint session_lte_launch_date check (
        launch_date <= session_date
    ),
    /* No sessions are conducted from 12pm to 2pm, before 9am, and beyond 6pm*/
    constraint valid_session_time check (
        (start_time >= 9 and end_time <= 12) or (start_time >= 14 and end_time <= 18)
    )
);

CREATE TABLE IF NOT EXISTS Registers (
    reg_date    date,
    sid         integer,
    course_id   integer,
    launch_date date,
    cc_number   char(20),

    primary key (reg_date, sid, course_id, launch_date, cc_number),
    foreign key (sid, course_id, launch_date) references Sessions,
    foreign key (cc_number) references Owns
);

CREATE TABLE IF NOT EXISTS Redeems (
    redeem_date         date,
    sid                 integer,
    course_id           integer,
    launch_date         date,
    transaction_date    date,
    cc_number           char(20),
    package_id          integer,

    primary key (
        redeem_date, sid, course_id, launch_date, transaction_date, cc_number, package_id
    ),
    foreign key (sid, course_id, launch_date) references Sessions,
    foreign key (transaction_date, cc_number, package_id) references Buys
);

-- TODO: Trigger to check that user can only cancel sessions that he has registered/redeemed.
CREATE TABLE IF NOT EXISTS Cancels (
    cancel_date     date,
    sid             integer,
    course_id       integer,
    launch_date     date,
    cust_id         integer,
    refund_amt      integer,
    package_credit  integer,

    primary key (
        cancel_date, sid, course_id, launch_date, cust_id
    ),
    foreign key (sid, course_id, launch_date) references Sessions,
    foreign key (cust_id) references Customers
);
