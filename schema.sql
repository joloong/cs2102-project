-- CS2102 Project Team 41 schema.sql

-- DONE:
-- ENTITIES:
-- Pay_slips, Employees, Instructors, Administrators, Managers,
-- Part_time_Emp, Full_time_Emp, Part_time_instructors, Full_time_instructors,
-- Customers, Credit_cards, Course_packages,
-- Courses, Sessions, Offerings,
-- Rooms, Course_areas

-- RELATIONS:
-- Owns, Buys, Registers, Redeems, Cancels

-- NOT DONE:
-- ENTITIES:
--
-- 
-- RELATIONS
--

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
    sid             SERIAL,
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
    /* No sessions are conducted from 12pm to 2pm*/
    constraint not_lunchtime_session check (
        end_time <= 12 or start_time >= 2
    )
);

-- TODO: Triggers to check if rid of sid has enough capacity.
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

    primary key (
        cancel_date, sid, course_id, launch_date, cust_id
    ),
    foreign key (sid, course_id, launch_date) references Sessions,
    foreign key (cust_id) references Customers
);

-- TRIGGERS & TRIGGER FUNCTIONS

CREATE OR REPLACE FUNCTION disable_owns_update_delete() RETURNS TRIGGER
AS $$
BEGIN
    RAISE EXCEPTION 'Updating or deleting of Owns is not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER disable_owns_update_delete_trigger
BEFORE UPDATE OR DELETE ON Owns
FOR EACH ROW EXECUTE FUNCTION disable_owns_update_delete();

CREATE OR REPLACE FUNCTION credit_cards_owns_key_constraint() RETURNS TRIGGER
AS $$
DECLARE
    credit_card_count INT;
BEGIN
    SELECT COUNT(*) INTO credit_card_count
    FROM Owns
    WHERE Owns.cc_number = NEW.cc_number;

    IF (credit_card_count >= 1) THEN
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER credit_cards_owns_key_constraint_trigger
BEFORE INSERT ON Owns
FOR EACH ROW EXECUTE FUNCTION credit_cards_owns_key_constraint();

CREATE OR REPLACE FUNCTION owns_participation_constraint() RETURNS TRIGGER
AS $$
DECLARE
    credit_card_count INT;
BEGIN
    SELECT COUNT(*) INTO credit_card_count
    FROM Owns
    WHERE Owns.cc_number = OLD.cc_number;

    IF (credit_card_count <= 1) THEN
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER owns_participation_constraint_trigger
BEFORE UPDATE OR DELETE ON Owns
FOR EACH ROW EXECUTE FUNCTION owns_participation_constraint();

CREATE OR REPLACE FUNCTION credit_cards_participation_constraint() RETURNS TRIGGER
AS $$
DECLARE
    credit_card_count INT;
BEGIN
    SELECT COUNT(*) INTO credit_card_count
    FROM Owns
    WHERE Owns.cc_number = NEW.cc_number;

    IF (credit_card_count < 1) THEN
        RAISE EXCEPTION 'Did not insert or update on Owns.';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER credit_cards_participation_constraint_trigger
AFTER INSERT OR UPDATE ON Credit_cards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_participation_constraint();

CREATE OR REPLACE FUNCTION customers_participation_constraint() RETURNS TRIGGER
AS $$
DECLARE
    customer_count INT;
BEGIN
    SELECT COUNT(*) INTO customer_count
    FROM Owns
    WHERE Owns.cust_id = NEW.cust_id;

    IF (customer_count < 1) THEN
        RAISE EXCEPTION 'Did not insert or update on Owns.';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER customers_participation_constraint_trigger
AFTER INSERT OR UPDATE ON Customers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION customers_participation_constraint();

-- TODO: What if customer change credit card?
CREATE OR REPLACE FUNCTION at_most_one_active_or_partially_active_package()
RETURNS TRIGGER
AS $$
DECLARE
    num_unused_sessions INT;
    last_transaction_date date;
    last_package_id INT;
    num_cancellable_sessions INT;
BEGIN
    SELECT num_remaining_registrations, transaction_date, package_id 
    INTO num_unused_sessions, last_transaction_date, last_package_id
    FROM Buys
    WHERE Buys.cc_number = NEW.cc_number
    ORDER BY transaction_date desc
    LIMIT 1;

    IF num_unused_sessions >= 1 THEN
        RAISE EXCEPTION 'There is an active course package.';
        RETURN NULL;
    END IF;

    SELECT COUNT(*)
    INTO num_cancellable_sessions
    FROM Redeems NATURAL JOIN Sessions
    WHERE Redeems.transaction_date = last_transaction_date
        AND Redeems.cc_number = NEW.cc_number
        AND Redeems.package_id = last_package_id
        AND Sessions.session_date - NOW() >= 7;

    IF num_cancellable_sessions >= 1 THEN
        RAISE EXCEPTION 'There is a partially active course package.';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER at_most_one_active_or_partially_active_package_trigger
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION at_most_one_active_or_partially_active_package();
