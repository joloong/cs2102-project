-- CS2102 Project Team 41 proc.sql

-- Routine Tracker
-- Completed/In-Process: 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 16, 17, 18, 19, 22
-- TODO: 10, 15, 20, 21, 23, 24, 25, 26, 27, 28, 29, 30

-- 1.
-- TODO: IF not administrator/manager/instructor
-- Assumptions: Course_areas should exist in the database
CREATE OR REPLACE PROCEDURE add_employee (name TEXT, address TEXT, phone TEXT, email TEXT, monthly_rate INT, hourly_rate INT, join_date DATE, employee_category TEXT, course_areas TEXT[])
AS $$
DECLARE
    new_eid INT;
    course_area TEXT;
BEGIN
    -- INPUT VALIDATION
    IF monthly_rate IS NULL AND hourly_rate IS NULL THEN
        RAISE EXCEPTION 'Salary information not supplied.';
    END IF;
    IF monthly_rate IS NOT NULL AND hourly_rate IS NOT NULL THEN
        RAISE EXCEPTION 'Only full-time or part-time salary information is to be supplied.';
    END IF;

    IF employee_category = 'administrator' AND array_length(course_areas, 1) > 0 THEN
        RAISE EXCEPTION 'Set of course areas should be empty for administrators';
    END IF;
    IF employee_category = 'instructor' AND array_length(course_areas, 1) IS NULL THEN
        RAISE EXCEPTION 'Set of course areas should not be empty for instructors specialization areas.';
    END IF;
    IF employee_category = 'manager' AND array_length(course_areas, 1) IS NULL THEN
        RAISE EXCEPTION 'Set of course areas should not be empty for managers managed areas.';
    END IF;

    -- MAIN OPERATION
    -- Insert - General
    INSERT INTO Employees (name, phone, email, join_date, address)
    VALUES (name, phone, email, join_date, address)
    RETURNING eid INTO new_eid;

    -- Insert - Specific
    IF monthly_rate IS NULL AND hourly_rate IS NOT NULL THEN
        IF employee_category = 'administrator' THEN
            RAISE EXCEPTION 'Administrators cannot be part time employeees';
        END IF;
        IF employee_category = 'manager' THEN
            RAISE EXCEPTION 'Managers cannot be part time employees';
        END IF;
        INSERT INTO Part_time_Emp (eid, hourly_rate)
        VALUES (new_eid, hourly_rate);
        IF employee_category = 'instructor' THEN
            INSERT INTO Instructors (eid)
            VALUES (new_eid);
            FOREACH course_area IN ARRAY course_areas LOOP
                INSERT INTO Specializes (eid, area)
                VALUES (new_eid, course_area);
            END LOOP;
            INSERT INTO Part_time_instructors (eid)
            VALUES (new_eid);
        END IF;
    END IF;

    IF monthly_rate IS NOT NULL AND hourly_rate IS NULL THEN
        INSERT INTO Full_time_Emp (eid, monthly_rate)
        VALUES (new_eid, monthly_rate);

        IF employee_category = 'administrator' THEN
            INSERT INTO Administrators (eid)
            VALUES (new_eid);
        END IF;
        IF employee_category = 'manager' THEN
            INSERT INTO Managers (eid)
            VALUES (new_eid);
        END IF;
        IF employee_category = 'instructor' THEN
            INSERT INTO Instructors (eid)
            VALUES (new_eid);
            FOREACH course_area IN ARRAY course_areas LOOP
                INSERT INTO Specializes (eid, area)
                VALUES (new_eid, course_area);
            END LOOP;
            INSERT INTO Full_time_instructors (eid)
            VALUES (new_eid);
        END IF;
    END IF;

END;
$$ LANGUAGE plpgsql;

-- 2.
CREATE OR REPLACE PROCEDURE remove_employee (eid INTEGER, depart_date DATE) 
AS $$
BEGIN
    IF depart_date IS NULL THEN
        RAISE EXCEPTION 'Depart date cannot be NULL';
    END IF;
    
    -- (1) the employee is an administrator who is handling some course 
    --     offering where its registration deadline is after the 
    --     employee’s departure date
    IF EXISTS (
            SELECT 1 
            FROM Offerings, Administrators
            WHERE Offerings.eid = Administrators.eid
            AND Administrators.eid = remove_employee.eid
            AND Offerings.registration_deadline > remove_employee.depart_date) THEN 
        RAISE EXCEPTION 'Cannot update employee - This administrator is still handling a course with a registration deadline that is not over yet (after their departure date).';
    END IF;
    -- (2) the employee is an instructor who is teaching some course
    --     session that starts after the employee’s departure date
    IF EXISTS (
            SELECT 1 
            FROM Sessions, Instructors
            WHERE Sessions.eid = Instructors.eid
            AND Instructors.eid = remove_employee.eid
            AND Sessions.launch_date > remove_employee.depart_date) THEN 
        RAISE EXCEPTION 'Cannot update employee - This instructor is teaching a course session that starts after their departure date.';
    END IF;
    -- (3) the employee is a manager who is managing some area.
    IF EXISTS (
            SELECT 1 
            FROM Course_areas, Managers
            WHERE Course_areas.eid = Managers.eid
            AND Managers.eid = remove_employee.eid) THEN 
        RAISE EXCEPTION 'Cannot update employee - This manager is currently managing an area.';
    END IF;

    UPDATE Employees
    SET depart_date = remove_employee.depart_date
    WHERE Employees.eid = remove_employee.eid;
END;
$$ LANGUAGE plpgsql;

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

-- 6.

-- Note: _session_start_hour should be a number in 24 hrs format, e.g. 4pm will be 16.
CREATE OR REPLACE FUNCTION find_instructors (_course_identifier INT, _session_date DATE, _session_start_hour INT)
RETURNS TABLE (eid INT, name text)
AS $$
DECLARE 
    session_duration INT;
    session_area TEXT;
    session_end_hour INT;
    session_month DOUBLE PRECISION;
    session_year DOUBLE PRECISION;
BEGIN
    SELECT duration, area into session_duration, session_area
    FROM Courses
    WHERE Courses.course_id = _course_identifier;

    -- As a session either ends before 12pm or starts after 2pm, we do not need to do modulo on the hours.
    session_end_hour := _session_start_hour + session_duration;

    session_month := extract(month from _session_date);
    session_year := extract(year from _session_date);

    RETURN QUERY
    with current_instructors AS (
        SELECT R1.eid
        FROM (Instructors NATURAL JOIN Employees) R1
        WHERE (R1.depart_date IS NULL) or (R1.depart_date >= _session_date)
    ), specialist_employees as (
        /* Instructors that specialize in the course area */
        SELECT R1.eid
        FROM (current_instructors NATURAL JOIN Specializes) R1
        WHERE R1.area = session_area
        /* drop Instructors that would exceed the max of 30 hours per month by taking up the session */
        EXCEPT
        SELECT R1.eid
        FROM Part_time_instructors R1
        WHERE (session_duration + (
            SELECT SUM(duration)
            FROM (Courses NATURAL JOIN Sessions) R2
            WHERE R1.eid = R2.eid and session_year = extract(year from R2.session_date) and session_month = extract(month from R2.session_date)
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
            (session_end_hour <= 12 and R2.end_time <= 12 or _session_start_hour >= 14 and R2.start_time >= 14) and (
                -- there is not at least an hour of break
                (R2.start_time - 1 < _session_start_hour and _session_start_hour < R2.end_time + 1) or 
                (_session_start_hour - 1 < R2.start_time and R2.start_time < session_end_hour + 1)
            )
        )
    );
END;
$$ LANGUAGE plpgsql;

-- 7.
/*
-- Note: the array of sorted hours will look something like this {9,10,14,15,16}, corresponding to 9am, 10am, 2pm, 3pm, 4pm respectively.
-- Note: Instructors that do not have any available slots on a given day are intentionally excluded from the result.
*/
CREATE OR REPLACE FUNCTION get_available_instructors (course_identifier INT, start_date DATE, end_date DATE)
RETURNS TABLE (eid INT, name text, assigned_hours_month_total INT, day DATE, available_hours_on_day INT[])
AS $$
DECLARE
    date_counter TIMESTAMP := start_date::TIMESTAMP;
    course_duration INT;
    time_counter1 INT := 9;
    time_counter2 INT := 14;
    r refcursor;
    temp RECORD;
    t1 INT;
    items RECORD;
BEGIN
    DROP TABLE IF EXISTS temp_table;
    CREATE TEMP TABLE IF NOT EXISTS temp_table (
        eid                         INT,
        name                        TEXT not null,
        assigned_hours_month_total  INT default 0,
        day                         DATE not null,
        available_hours_on_day      INT[],
        PRIMARY KEY (eid, day)
    );
    SELECT duration INTO course_duration FROM Courses WHERE course_id = course_identifier;

    WHILE date_counter <= end_date::TIMESTAMP LOOP

        WITH eid_hours AS (
            -- eid's who have non-zero working hours
            SELECT distinct R1.eid, SUM(Coalesce(R1.duration, 0)) as assigned_hours_month_total
            FROM (Instructors NATURAL LEFT JOIN Sessions NATURAL LEFT JOIN Courses) R1
            WHERE R1.session_date IS NOT NULL 
                and extract(year from R1.session_date) = extract(year from date_counter) 
                and extract(month from R1.session_date) = extract(month from date_counter) 
            GROUP BY R1.eid
        )
        INSERT INTO temp_table (eid, name, assigned_hours_month_total, day, available_hours_on_day)
        SELECT R1.eid, R1.name, Coalesce(R1.assigned_hours_month_total, 0), date_counter, ARRAY[]::INT[]
        FROM (Instructors NATURAL JOIN Employees NATURAL LEFT JOIN eid_hours) R1;

        -- consider session slots from 9am-12pm
        WHILE time_counter1 <= (12 - course_duration) LOOP
            -- consider time_counter1 as the session start time
            FOR temp IN SELECT find_instructors(course_identifier, TO_CHAR(date_counter, 'YYYY-MM-DD')::DATE, time_counter1)
            LOOP
                t1 := row_to_json(temp)->'find_instructors'->'eid';
                UPDATE temp_table
                SET available_hours_on_day = temp_table.available_hours_on_day || ARRAY[time_counter1] /* array concatenation */
                WHERE temp_table.day::DATE = date_counter::date and temp_table.eid = t1;
            END LOOP;
            time_counter1 := time_counter1 + 1;
        END LOOP;
        -- consider session slots from 2pm-6pm
        WHILE time_counter2 <= (18 - course_duration) LOOP
            -- consider time_counter2 as the session start time
            FOR temp IN SELECT find_instructors(course_identifier, TO_CHAR(date_counter, 'YYYY-MM-DD')::DATE, time_counter2)
            LOOP
                t1 := row_to_json(temp)->'find_instructors'->'eid';
                UPDATE temp_table
                SET available_hours_on_day = temp_table.available_hours_on_day || ARRAY[time_counter2] /* array concatenation */
                WHERE temp_table.day::DATE = date_counter::date and temp_table.eid = t1;
            END LOOP;
            time_counter2 := time_counter2 + 1;
        END LOOP;

        date_counter := date_counter + '1 day'::INTERVAL;
        time_counter1 := 9;
        time_counter2 := 14;
    END LOOP;

    RETURN QUERY
    SELECT * FROM temp_table tt
    WHERE cardinality(tt.available_hours_on_day) > 0
    ORDER BY tt.day, tt.eid;
END;
$$ LANGUAGE plpgsql;

-- 8.
CREATE OR REPLACE FUNCTION find_rooms (_session_date DATE, _session_start_hour INT, _session_duration INT)
RETURNS TABLE (rid INT)
AS $$
DECLARE
    _session_end_hour INT;
BEGIN
    _session_end_hour := _session_start_hour + _session_duration;
    RETURN QUERY
    SELECT R1.rid
    FROM (Rooms NATURAL LEFT JOIN Sessions) R1
    WHERE R1.session_date IS NULL or (TO_CHAR(R1.session_date, 'YYYY-MM-DD')::DATE != TO_CHAR(_session_date, 'YYYY-MM-DD')::DATE) or not (
        -- if a given session in R1 is on the same date as _session_date, ensure they don't overlap
            (R1.start_time <= _session_start_hour and _session_start_hour < R1.end_time) or 
            (_session_start_hour <= R1.start_time and R1.start_time < _session_end_hour)
    )
    ORDER BY R1.rid;
END;
$$ LANGUAGE plpgsql;

-- 9.
/*
Note: Rooms that are not available on a given day are intentionally excluded from the result.
*/
CREATE OR REPLACE FUNCTION get_available_rooms (start_date DATE, end_date DATE)
RETURNS TABLE (rid INT, room_capacity INT, day DATE, available_hours_on_day INT[])
AS $$
DECLARE
    date_counter TIMESTAMP := start_date::TIMESTAMP;
    session_slots INT[] := array[9, 10, 11, 14, 15, 16, 17];
    slot_hour INT;
    temp RECORD;

BEGIN
    DROP TABLE IF EXISTS temp_room_table;
    CREATE TEMP TABLE IF NOT EXISTS temp_room_table (
        rid                     INT,
        room_capacity           INT not null,
        day                     DATE not null,
        available_hours_on_day  INT[],
        PRIMARY KEY (rid, day)
    );

    WHILE date_counter <= end_date::TIMESTAMP LOOP

        INSERT INTO temp_room_table (rid, room_capacity, day, available_hours_on_day)
        SELECT R1.rid, R1.seating_capacity as room_capacity, date_counter::DATE, ARRAY[]::INT[]
        FROM Rooms R1;

        -- availability of each room over all session_slots in a day
        FOREACH slot_hour IN array session_slots LOOP
            FOR temp IN
                -- obtain a list of all the rooms that are available at this slot.
                SELECT R1.rid
                FROM Rooms R1
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM Sessions S1
                    WHERE S1.rid = R1.rid and date_counter::DATE = S1.session_date::DATE and (
                        S1.start_time <= slot_hour and slot_hour < S1.end_time
                    )
                )
            LOOP
                UPDATE temp_room_table
                SET available_hours_on_day = temp_room_table.available_hours_on_day || ARRAY[slot_hour] /* array concatenation */
                WHERE temp_room_table.rid = temp.rid;
            END LOOP;
        END LOOP;

        date_counter := date_counter + '1 day'::INTERVAL;
    END LOOP;

    RETURN QUERY
    SELECT * FROM temp_room_table tt
    WHERE cardinality(tt.available_hours_on_day) > 0
    ORDER BY tt.day, tt.rid;
END;
$$ LANGUAGE plpgsql;

-- 10. 
/*
Note to whoever is doing this function:

For routine number 10 (add_course_offering), there's a missing input parameter for the target number of registrations. The second sentence should read:

The inputs to the routine include the following: course offering identifier, course identifier, course fees, launch date, registration deadline,  target number of registrations, administrator’s identifier, and information for each session (session date, session start hour, and room identifier).
*/

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

-- 13.
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

-- 16.
/*
Assumption: it is not possible to register for an offering whose launch_date is in the future.
*/
CREATE OR REPLACE FUNCTION get_available_course_sessions (_course_id INT)
RETURNS TABLE (session_date DATE, session_start_hour INT, instructor_name TEXT, remaining_seats INT)
AS $$
BEGIN
    RETURN QUERY
    SELECT s1.session_date, s1.start_time, (SELECT e1.name FROM Employees e1 WHERE e1.eid = s1.eid), 
        (
            SELECT R3.seating_capacity FROM Rooms R3 WHERE R3.rid = s1.rid
        ) - (
            SELECT COUNT(*)::INT FROM Registers R2
            WHERE R2.sid = s1.sid and R2.course_id = s1.course_id and R2.launch_date = s1.launch_date
        )
    FROM Sessions s1 INNER JOIN Offerings o1 ON s1.course_id = o1.course_id and s1.launch_date = o1.launch_date
    WHERE s1.course_id = _course_id and NOW()::DATE >= s1.launch_date::DATE and NOW()::DATE <= o1.registration_deadline::DATE and (
        -- session can be registered only if capacity of the session is less than that of the room
        (
            SELECT COUNT(*)::INT
            FROM Registers R2
            WHERE R2.sid = s1.sid and R2.course_id = s1.course_id and R2.launch_date = s1.launch_date
        ) < (
            SELECT R3.seating_capacity
            FROM Rooms R3
            WHERE R3.rid = s1.rid
        )
    )
    ORDER BY s1.session_date, s1.start_time;
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

-- 18.
CREATE OR REPLACE FUNCTION get_my_registrations (cust_id INT) 
RETURNS TABLE (title TEXT, fees INT, session_date DATE, start_time INT, duration INT)
AS $$
DECLARE
    cust_cc_number char(20);
BEGIN
    SELECT cc_number INTO cust_cc_number
    FROM Owns
    WHERE Owns.cust_id = get_my_registrations.cust_id
    ORDER BY from_date desc
    LIMIT 1;

    RETURN query
    WITH RegisteredSessions AS (
        SELECT sid, course_id, launch_date
        FROM Registers
        WHERE Registers.cc_number = cust_cc_number
        UNION
        SELECT sid, course_id, launch_date
        FROM Redeems
        WHERE Redeems.cc_number = cust_cc_number
        EXCEPT
        SELECT sid, course_id, launch_date
        FROM Cancels
        WHERE Cancels.cust_id = get_my_registrations.cust_id
    )
    SELECT RSC.title, O.fees, RSC.session_date, RSC.start_time, RSC.duration
    FROM (RegisteredSessions NATURAL JOIN Sessions NATURAL JOIN Courses) RSC
        JOIN Offerings O
        ON RSC.launch_date = O.launch_date AND
            RSC.course_id = O.course_id
    WHERE RSC.session_date <= NOW() AND 
        EXTRACT(HOUR from current_time) < RSC.end_time;
END;
$$ LANGUAGE plpgsql;

-- 19.
CREATE OR REPLACE PROCEDURE update_course_session (cust_id INT, course_id INT, launch_date date, new_sid INT) 
AS $$
DECLARE
    cust_cc_number char(20);
    new_seating_capacity INT;
    original_sid INT;
BEGIN
    SELECT cc_number INTO cust_cc_number
    FROM Owns
    WHERE Owns.cust_id = update_course_session.cust_id
    ORDER BY from_date desc
    LIMIT 1;

    SELECT seating_capacity
    INTO new_seating_capacity
    FROM Sessions NATURAL JOIN Rooms
    WHERE Sessions.launch_date = update_course_session.launch_date
        AND Sessions.course_id = update_course_session.course_id
        AND Sessions.sid = update_course_session.new_sid;

    IF new_seating_capacity >= 1 AND cust_cc_number IS NOT NULL THEN
        WITH RegisterNotCancelled AS (
            SELECT sid
            FROM Registers
            WHERE Registers.launch_date = update_course_session.launch_date
                AND Registers.course_id = update_course_session.course_id
                AND Registers.cc_number = cust_cc_number
            EXCEPT
            SELECT sid
            FROM Cancels
            WHERE Cancels.launch_date = update_course_session.launch_date
                AND Cancels.course_id = update_course_session.course_id
                AND Cancels.cust_id = update_course_session.cust_id
        )
        SELECT sid
        INTO original_sid
        FROM RegisterNotCancelled
        LIMIT 1; -- Should be implicit that there is at most 1 possible sid.

        IF original_sid IS NOT NULL THEN
            UPDATE Registers
            SET Registers.sid = update_course_session.new_sid
            WHERE Registers.sid = original_sid
                AND Registers.launch_date = update_course_session.launch_date
                AND Registers.course_id = update_course_session.course_id
                AND Registers.cc_number = cust_cc_number;
        ELSE
            WITH RedeemNotCancelled AS (
                SELECT sid
                FROM Redeems
                WHERE Redeems.launch_date = update_course_session.launch_date
                    AND Redeems.course_id = update_course_session.course_id
                    AND Redeems.cc_number = cust_cc_number
                EXCEPT
                SELECT sid
                FROM Cancels
                WHERE Cancels.launch_date = update_course_session.launch_date
                    AND Cancels.course_id = update_course_session.course_id
                    AND Cancels.cust_id = update_course_session.cust_id
            )
            SELECT sid
            INTO original_sid
            FROM RedeemNotCancelled
            LIMIT 1; -- Should be implicit that there is at most 1 possible sid.

            IF original_sid IS NOT NULL THEN
                UPDATE Redeems
                SET Redeems.sid = update_course_session.new_sid
                WHERE Redeems.sid = original_sid
                    AND Redeems.launch_date = update_course_session.launch_date
                    AND Redeems.course_id = update_course_session.course_id
                    AND Redeems.cc_number = cust_cc_number;
            END IF;
        END IF;
        
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

    IF NOW() < session_start_date OR (NOW() == session_start_date AND EXTRACT(HOUR from current_time) < session_start_time) THEN
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

-- 23.
CREATE OR REPLACE PROCEDURE remove_session (course_id INT, launch_date date, sid INT)
AS $$
DECLARE
    session_start_date date;
    session_start_time INT;
    num_registrations INT;
    num_redeems INT;
    num_cancels INT;
BEGIN
    SELECT session_date, start_time INTO session_start_date, session_start_time
    FROM Sessions
    WHERE Sessions.course_id = remove_session.course_id AND
        Sessions.launch_date = remove_session.launch_date AND
        Sessions.sid = remove_session.sid;

    IF NOW() < session_start_date OR (NOW() == session_start_date AND EXTRACT(HOUR from current_time) < session_start_time) THEN
        SELECT COUNT(*) INTO num_registrations
        FROM Registers
        WHERE Registers.course_id = remove_session.course_id AND
            Registers.launch_date = remove_session.launch_date AND
            Registers.sid = remove_session.sid;

        SELECT COUNT(*) INTO num_redeems
        FROM Redeems
        WHERE Redeems.course_id = remove_session.course_id AND
            Redeems.launch_date = remove_session.launch_date AND
            Redeems.sid = remove_session.sid;

        SELECT COUNT(*) INTO num_cancels
        FROM Cancels
        WHERE Cancels.course_id = remove_session.course_id AND
            Cancels.launch_date = remove_session.launch_date AND
            Cancels.sid = remove_session.sid;

        IF num_registrations + num_redeems - num_cancels <= 0 THEN
            DELETE FROM Sessions
            WHERE Sessions.course_id = remove_session.course_id AND
                Sessions.launch_date = remove_session.launch_date AND
                Sessions.sid = remove_session.sid;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 24.
CREATE OR REPLACE PROCEDURE add_session (course_id INT, launch_date date, sid INT, session_date date, start_time INT, rid INT, eid INT)
AS $$
DECLARE
    course_duration INT;
    registration_deadline DATE;
    before_registration_deadline boolean;
    valid_instructor boolean;
    valid_room boolean;
BEGIN
    SELECT Courses.duration INTO course_duration
    FROM Courses
    WHERE Courses.course_id = add_session.course_id;

    SELECT Offerings.registration_deadline INTO registration_deadline
    FROM Offerings
    WHERE Offerings.course_id = add_session.course_id AND
        Offerings.launch_date = add_session.launch_date;

    before_registration_deadline := NOW() <= registration_deadline;
    IF before_registration_deadline THEN
        valid_instructor := add_session.eid IN (
            SELECT I.eid
            FROM find_instructors(course_id, session_date, start_time) I
        );
        valid_room := add_session.rid IN (
            SELECT R.rid
            FROM find_rooms(session_date, start_time, course_duration) R
        );
        IF valid_instructor AND valid_room THEN
            INSERT INTO Sessions (sid, course_id, launch_date, session_date, start_time, end_time, rid, eid)
            VALUES (sid, course_id, launch_date, session_date, start_time, start_time + course_duration, rid, eid);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- For Testing
-- CALL add_employee('Employee1', 'Singapore', '98385373', 'employee1@u.nus.edu', '300', NULL, '2021-01-02', 'administrator', '{}');
-- CALL add_employee('Employee2', 'Singapore', '88984232', 'employee2@u.nus.edu', NULL, '10', '2021-02-02', 'instructor', '{}');
-- CALL add_customer('Joel', 'CCK', '82345678', 'joel@joel.com', '1234123412341234', 123, '2021-01-01');
-- CALL add_course_package('TESTING', 10, 5, '2021-01-01', '2021-05-05');
-- CALL buy_course_package(1, 1);
-- SELECT get_my_course_package(1);
