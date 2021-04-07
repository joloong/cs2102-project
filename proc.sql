-- CS2102 Project Team 41 proc.sql

DROP FUNCTION IF EXISTS find_instructors (INTEGER, DATE, INTEGER);

-- 3.
CREATE OR REPLACE PROCEDURE add_customer (cust_name TEXT, address TEXT, phone TEXT, email TEXT, cc_number char(20), cvv INT, expiry_date DATE)
AS $$
DECLARE
    new_cust_id INT;
BEGIN
	INSERT INTO Customers (cust_name, address, phone, email)
	VALUES (cust_name, address, phone, email)
    RETURNING cust_id INTO new_cust_id;

    INSERT INTO Credit_cards (cc_number, cvv, expiry_date)
    VALUES (cc_number, cvv, expiry_date);

    INSERT INTO Owns (cc_number, cust_id, from_date)
    VALUES (cc_number, new_cust_id, NOW());
END;
$$ LANGUAGE plpgsql;

-- 4.
CREATE OR REPLACE PROCEDURE update_credit_card (cust_id INT, cc_number char(20), cvv INT, expiry_date DATE)
AS $$
BEGIN
    INSERT INTO Credit_cards (cc_number, cvv, expiry_date)
    VALUES (cc_number, cvv, expiry_date);

    INSERT INTO Owns (cc_number, cust_id, from_date)
    VALUES (cc_number, new_cust_id, NOW());
END;
$$ LANGUAGE plpgsql;

-- 6.
CREATE OR REPLACE FUNCTION find_instructors (_course_identifier INT, _session_date DATE, _session_start_hour INT)
RETURNS TABLE (eid INT, name text)
AS $$
DECLARE 
    session_duration INT;
    session_area TEXT;
    session_end_hour INT;
    session_month DOUBLE PRECISION;
BEGIN
    SELECT duration, area into session_duration, session_area
    FROM Courses
    WHERE Courses.course_id = _course_identifier;

    -- As a session either ends before 12pm or starts after 2pm, we do not need to do modulo on the hours.
    session_end_hour := _session_start_hour + session_duration;

    session_month := extract(month from _session_date);

    RETURN QUERY
    with specialist_employees as (
        /* Instructors that specialize in the course area */
        SELECT R1.eid
        FROM Instructors R1
        WHERE R1.area = session_area
        /* drop Instructors that would exceed the max of 30 hours per month by taking up the session */
        EXCEPT
        SELECT R1.eid
        FROM Part_time_instructors R1
        WHERE (session_duration + (
            SELECT SUM(duration)
            FROM (Courses NATURAL JOIN Sessions) R2
            WHERE R1.eid = R2.eid and (session_month = extract(month from R2.session_date))
        ) > 30)
    ), instructor_names AS (
        SELECT R1.eid, R1.name
        FROM (specialist_employees NATURAL JOIN Employees) R1
    )
    /* remaining Instructors that do not have any scheduling restrictions with this session */
    SELECT DISTINCT R1.eid, R1.name
    FROM instructor_names R1
    WHERE NOT EXISTS (
        SELECT 1
        FROM (instructor_names NATURAL LEFT JOIN Sessions) R2
        WHERE R1.eid = R2.eid and _session_date = R2.session_date and (
            -- both sessions need to be in the morning/afternoon to have a chance of overlapping
            (session_end_hour <= 12 and R2.end_time <= 12 or _session_start_hour >= 2 and R2.start_time >= 2) and (
                ABS(R2.start_time - _session_start_hour) <= 1 or
                ABS(R2.end_time - _session_start_hour) <= 1 or
                ABS(R2.start_time - session_end_hour) <= 1 or
                ABS(R2.end_time - session_end_hour) <= 1
            )
        )
    );
END;
$$ LANGUAGE plpgsql;

-- 11.
CREATE OR REPLACE PROCEDURE add_course_package (package_name TEXT, price INT, num_free_registrations INT, sale_start_date DATE, sale_end_date DATE)
AS $$
BEGIN
    INSERT INTO Course_packages (package_name, price, num_free_registrations, sale_start_date, sale_end_date)
    VALUES (package_name, price, num_free_registrations, sale_start_date, sale_end_date);
END;
$$ LANGUAGE plpgsql;

-- 12.
CREATE OR REPLACE FUNCTION get_available_course_packages ()
RETURNS TABLE (package_name TEXT, num_free_registrations INT, sale_end_date DATE, price INT)
AS $$
    SELECT package_name, num_free_registrations, sale_end_date, price
    FROM Course_packages
    WHERE sale_end_date >= NOW();
$$ LANGUAGE sql;

-- 13. TODO: Each customer can have at most one active or partially active package.
CREATE OR REPLACE PROCEDURE buy_course_package (cust_id INT, package_id INT)
AS $$
DECLARE 
    cust_cc_number char(20);
    num_remaining_registrations INT;
BEGIN
    SELECT cc_number INTO cust_cc_number
    FROM Owns
    WHERE Owns.cust_id = buy_course_package.cust_id
    ORDER BY from_date desc
    LIMIT 1;

    SELECT num_free_registrations INTO num_remaining_registrations
    FROM Course_packages
    WHERE Course_packages.package_id = buy_course_package.package_id;

    INSERT INTO Buys (transaction_date, cc_number, package_id, num_remaining_registrations)
    VALUES (NOW(), cust_cc_number, package_id, num_remaining_registrations);
END;
$$ LANGUAGE plpgsql;

-- 14.
CREATE OR REPLACE FUNCTION get_my_course_package (cust_id INT)
RETURNS JSON
AS $$
DECLARE
    package_row record;
    session_json json;
BEGIN
    SELECT * INTO package_row
    FROM Course_packages cp natural join Buys b natural join Owns o
    WHERE o.cust_id = get_my_course_package.cust_id
    ORDER BY b.transaction_date desc
    LIMIT 1;
    
    WITH Sess AS (
        SELECT co.title, s.session_date, s.start_time
        FROM Redeems r natural join Sessions s natural join Courses co
        WHERE package_row.transaction_date = r.transaction_date AND
            package_row.cc_number = r.cc_number AND
            package_row.package_id = r.package_id
        ORDER BY s.session_date asc, s.start_time asc
    )
    SELECT json_agg(Sess) INTO session_json
    FROM Sess;

    RETURN json_build_object(
		'package_name', package_row.package_name,
        'transaction_date', package_row.transaction_date,
        'price', package_row.price,
        'num_free_registrations', package_row.num_free_registrations,
        'num_remaining_registrations', package_row.num_remaining_registrations,
        'redeemed_sessions_information', session_json
	);
END;
$$ LANGUAGE plpgsql;

-- 22. TODO: Check start_time too
CREATE OR REPLACE PROCEDURE update_room (course_id INT, launch_date date, sid INT, new_rid INT)
AS $$
DECLARE 
    session_start_date date;
    num_registrations INT;
    num_redeems INT;
    num_cancels INT;
    new_seating_capacity INT;
BEGIN
    SELECT sessions_date INTO session_start_date
    FROM Sessions
    WHERE Sessions.course_id = update_room.course_id AND
        Sessions.launch_date = update_room.launch_date AND
        Sessions.sid = update_room.sid;

    IF session_start_date < NOW() THEN
        SELECT COUNT(*) INTO num_registrations
        FROM Registers
        WHERE Registers.course_id = update_room.course_id AND
            Registers.launch_date = update_room.launch_date AND
            Registers.sid = update_room.sid;

        SELECT COUNT(*) INTO num_redeems
        FROM Redeems
        WHERE Redeems.course_id = update_room.course_id AND
            Redeems.launch_date = update_room.launch_date AND
            Redeems.sid = update_room.sid;

        SELECT COUNT(*) INTO num_cancels
        FROM Cancels
        WHERE Cancels.course_id = update_room.course_id AND
            Cancels.launch_date = update_room.launch_date AND
            Cancels.sid = update_room.sid;

        SELECT seating_capacity INTO new_seating_capacity
        FROM Rooms
        WHERE Rooms.rid = update_room.new_rid;

        IF num_registrations + num_redeems - num_cancels <= new_seating_capacity THEN
            UPDATE Sessions
            SET Sessions.rid = update_room.new_rid
            WHERE Sessions.course_id = update_room.course_id AND
                Sessions.launch_date = update_room.launch_date AND
                Sessions.sid = update_room.sid;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- For Testing
-- CALL add_customer('Joel', 'CCK', '82345678', 'joel@joel.com', '1234123412341234', 123, '2021-01-01');
-- CALL add_course_package('TESTING', 10, 5, '2021-01-01', '2021-05-05');
-- CALL buy_course_package(1, 1);
-- SELECT get_my_course_package(1);