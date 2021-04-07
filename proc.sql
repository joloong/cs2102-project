-- CS2102 Project Team 41 proc.sql

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

-- 5.
CREATE OR REPLACE PROCEDURE add_course (title TEXT, description TEXT, area TEXT, duration INT)
AS $$
BEGIN
    INSERT INTO Courses (title, duration, area, description)
    VALUES (title, duration, area, description);
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

-- 17. TODO: Implement triggers to check valid
CREATE OR REPLACE PROCEDURE register_session (cust_id INT, course_id INT, launch_date date, sid INT, payment_method TEXT)
AS $$
DECLARE 
    cust_cc_number char(20);
    cust_transaction_date date;
    cust_package_id INT;
BEGIN
    SELECT cc_number INTO cust_cc_number
    FROM Owns
    WHERE Owns.cust_id = register_session.cust_id
    ORDER BY from_date desc
    LIMIT 1;

    IF payment_method = 'credit_card' THEN
        INSERT INTO Registers (reg_date, sid, course_id, launch_date, cc_number)
	    VALUES (NOW(), sid, course_id, launch_date, cust_cc_number);
    ELSE -- redeems
        SELECT transaction_date, package_id INTO cust_transaction_date, cust_package_id
        FROM Buys
        WHERE Buys.cc_number = cust_cc_number
        ORDER BY Buys.transaction_date desc
        LIMIT 1;

        INSERT INTO Redeems (redeem_date, sid, course_id, launch_date, transaction_date, cc_number, package_id)
	    VALUES (NOW(), sid, course_id, launch_date, cust_transaction_date, cust_cc_number, cust_package_id);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 22.
CREATE OR REPLACE PROCEDURE update_room (course_id INT, launch_date date, sid INT, new_rid INT)
AS $$
DECLARE 
    session_start_date date;
    session_start_time INT;
    num_registrations INT;
    num_redeems INT;
    num_cancels INT;
    new_seating_capacity INT;
BEGIN
    SELECT session_date, start_time INTO session_start_date, session_start_time
    FROM Sessions
    WHERE Sessions.course_id = update_room.course_id AND
        Sessions.launch_date = update_room.launch_date AND
        Sessions.sid = update_room.sid;

    IF session_start_date < NOW() AND EXTRACT(HOUR from current_time) < session_start_time THEN
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
