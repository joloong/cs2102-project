-- CS2102 Project Team 41 schema.sql

-- DONE:
-- ENTITIES:
-- Pay_slips, Employees, Instructors, Administrators, Managers,
-- Part_time_Emp, Full_time_Emp, Part_time_instructors, Full_time_instructors,
-- Customers, Credit_cards, Course_packages,
-- Courses, Sessions, Offerings,
--
-- RELATIONS:
-- Owns, Buys, Registers, Redeems, Cancels

-- NOT DONE:
-- ENTITIES:
-- Course_areas, Rooms
-- 
-- RELATIONS
-- Manages, Handles, Specializes, In, Conducts

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
    eid             char(20) primary key references Part_time_Emp
                    on delete cascade           
);

CREATE TABLE IF NOT EXISTS Full_time_instructors (
    eid             char(20) primary key references Full_time_Emp
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Administrators (
    eid             char(20) primary key references Full_time_Emp
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Managers (
    eid             char(20) primary key references Full_time_Emp
                    on delete cascade
);

CREATE TABLE IF NOT EXISTS Pay_slips (
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

CREATE TABLE IF NOT EXISTS Buys (
    transaction_date            date,
    cc_number                   char(20),
    package_id                  char(20),
    num_remaining_registrations integer not null,

    primary key (transaction_date, cc_number, package_id),
    foreign key (cc_number) references Owns(cc_number),
    foreign key (package_id) references Course_packages(package_id)
);

CREATE TABLE IF NOT EXISTS Courses (
    course_id   char(20)    primary key,
    title		text     	not null,
    duration	integer     not null,
    description	text
);

CREATE TABLE IF NOT EXISTS Offerings (
	course_id					char(20),
    launch_date					date,
    start_date					date	    not null,
	end_date					date	    not null,
	registration_deadline		date	    not null,
    fees						integer     not null,
    seating_capacity			integer     not null,
    target_number_registrations	integer     not null,
	
	primary key	(launch_date, course_id),
	foreign key	(course_id) references Courses,
	
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

CREATE TABLE IF NOT EXISTS Sessions (
    sid   			char(20),
	course_id		char(20),
	launch_date		date,
    session_date	date		not null,
    start_time		integer     not null,
	end_time		integer		not null, 
	
	primary key (sid, course_id, launch_date),
	foreign key (launch_date, course_id) references Offerings,
	
	constraint end_lte_start_time check (
		start_time <= end_time
	),
	constraint session_lte_launch_date check (
		launch_date <= session_date
	)
);

CREATE TABLE IF NOT EXISTS Registers (
    reg_date	date,
	sid 		char(20),
	course_id	char(20),
	launch_date	date,
    cc_number 	char(20),
	
	primary key (reg_date, sid, course_id, launch_date, cc_number),
	foreign key (sid, course_id, launch_date) references Sessions,
	foreign key (cc_number) references Owns
);

CREATE TABLE IF NOT EXISTS Redeems (
    redeem_date			date,
	sid 				char(20),
	course_id			char(20),
	launch_date			date,
    transaction_date	date,
    cc_number           char(20),
    package_id          char(20),
	
	primary key (
		redeem_date, sid, course_id, launch_date, transaction_date, cc_number, package_id
	),
	foreign key (sid, course_id, launch_date) references Sessions,
	foreign key (transaction_date, cc_number, package_id) references Buys
);

CREATE TABLE IF NOT EXISTS Cancels (
    cancel_date		date,
	sid 			char(20),
	course_id		char(20),
	launch_date		date,
	cust_id 		char(20),
	
	primary key (
		cancel_date, sid, course_id, launch_date, cust_id
	),
	foreign key (sid, course_id, launch_date) references Sessions,
	foreign key (cust_id) references Customers
);
