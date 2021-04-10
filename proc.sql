-- CS2102 Project Team 41 proc.sql

DROP FUNCTION IF EXISTS
find_instructors, get_available_instructors, find_rooms, get_available_rooms, get_available_course_packages,
get_my_course_package, get_available_course_offerings, get_available_course_sessions, get_my_registrations, pay_salary,
promote_courses, top_packages, popular_courses, view_summary_report, view_manager_report;

DROP PROCEDURE IF EXISTS
add_employee, remove_employee, add_customer, update_credit_card, add_course, add_course_offering,
add_course_package, buy_course_package, register_session, update_course_session, cancel_registration,
update_instructors, update_room, remove_session, add_session;

-- Routine Tracker
-- Completed/In-Process: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
-- TODO: 30

-- 1.
-- Assumptions: Course_areas should exist in the database
CREATE OR REPLACE PROCEDURE add_employee (name TEXT, address TEXT, phone TEXT, email TEXT, monthly_salary INT, hourly_rate INT, join_date DATE, employee_category TEXT, course_areas TEXT[])
AS $$
DECLARE
    new_eid INT;
    course_area TEXT;
BEGIN
    -- INPUT VALIDATION
    IF monthly_salary IS NULL AND hourly_rate IS NULL THEN
        RAISE EXCEPTION 'Salary information not supplied.';
    END IF;
    IF monthly_salary IS NOT NULL AND hourly_rate IS NOT NULL THEN
        RAISE EXCEPTION 'Only full-time or part-time salary information is to be supplied.';
    END IF;

    IF employee_category = 'administrator' AND array_length(course_areas, 1) > 0 THEN
        RAISE EXCEPTION 'Set of course areas should be empty for administrators';
    END IF;
    IF employee_category = 'instructor' THEN
        IF array_length(course_areas, 1) IS NULL THEN
            RAISE EXCEPTION 'Set of course areas should not be empty for instructors specialization areas.';
        END IF;
        FOREACH course_area IN ARRAY course_areas LOOP
            IF (SELECT COUNT(*) FROM Course_areas WHERE Course_areas.area = course_area) = 0 THEN
                RAISE EXCEPTION 'The new instructor has an specialization area that does not exist';
            END IF;
        END LOOP;
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
    IF monthly_salary IS NULL AND hourly_rate IS NOT NULL THEN
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

    IF monthly_salary IS NOT NULL AND hourly_rate IS NULL THEN
        INSERT INTO Full_time_Emp (eid, monthly_salary)
        VALUES (new_eid, monthly_salary);

        IF employee_category = 'administrator' THEN
            INSERT INTO Administrators (eid)
            VALUES (new_eid);
        END IF;
        IF employee_category = 'manager' THEN
            INSERT INTO Managers (eid)
            VALUES (new_eid);
            FOREACH course_area IN ARRAY course_areas LOOP
                IF (SELECT COUNT(*) FROM Course_areas WHERE Course_areas.area = course_area) = 0 THEN
                    INSERT INTO Course_areas (area, eid)
                    VALUES (course_area, new_eid);
                END IF;
            END LOOP;
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
CREATE OR REPLACE PROCEDURE remove_employee (eid INT, depart_date DATE) 
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
/*
Note: _session_start_hour should be a number in 24 hrs format, e.g. 4pm will be 16.
*/
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
The inputs to the routine include the following: course offering identifier, course identifier, course fees, launch date, registration deadline,  target number of registrations, administrator’s identifier, and information for each session (session date, session start hour, and room identifier).
*/
CREATE OR REPLACE PROCEDURE add_course_offering(course_id INT, fees INT, launch_date DATE, registration_deadline DATE, target_number_registrations INT, eid INT, session_date DATE[], session_start_hour INT[], room_id INT[])
AS $$
DECLARE
    start_date DATE;
    end_date DATE;
    course_duration INT;
    current_available_instructor INT;
    current_sid INT; -- For a new course offering, session id will start from 1
    total_seating_capacity INT;
    current_seating_capacity INT;
BEGIN
    IF (add_course_offering.eid NOT IN (SELECT Administrators.eid FROM Administrators)) THEN
        RAISE EXCEPTION 'Administrator specified does not exist';
    END IF;
    IF (add_course_offering.course_id NOT IN (SELECT Courses.course_id FROM Courses)) THEN
        RAISE EXCEPTION 'Course specified does not exist';
    END IF;
    IF (array_length(session_date, 1) IS NULL 
        OR array_length(session_start_hour, 1) IS NULL 
        OR array_length(room_id, 1) IS NULL) THEN
        RAISE EXCEPTION 'Invalid sessions information';
    END IF;
    -- Should be same length
    IF array_length(session_date, 1) <> array_length(session_start_hour, 1)
        OR array_length(session_date, 1) <> array_length(room_id, 1) 
        OR array_length(session_start_hour, 1) <> array_length(room_id, 1) THEN
        RAISE EXCEPTION 'Missing sessions information';
    END IF;
    
    SELECT duration INTO course_duration
    FROM Courses
    WHERE Courses.course_id = add_course_offering.course_id; -- use course_id = 1
    
    total_seating_capacity := 0;
    FOR i IN 1..array_length(room_id, 1)
    LOOP
        SELECT seating_capacity INTO current_seating_capacity
        FROM Rooms
        WHERE rid = room_id[i];

        IF (room_id[i] IS NULL) THEN
            RAISE EXCEPTION 'Room % is not available', room_id[i];
        END IF;

        total_seating_capacity := total_seating_capacity + current_seating_capacity;
    END LOOP;

    FOR i IN 1..array_length(session_date, 1)
    LOOP    
        IF start_date IS NULL THEN
            start_date := session_date[i];
        END IF;

        IF session_date[i] < start_date THEN
            start_date := session_date[i];
        END IF;

        IF end_date IS NULL THEN
            end_date := session_date[i];
        END IF;

        IF session_date[i] > end_date THEN
            end_date := session_date[i];
        END IF;
    END LOOP;

    INSERT INTO Offerings (course_id, launch_date, start_date, end_date, registration_deadline, fees, seating_capacity, target_number_registrations, eid)
    VALUES (course_id, launch_date, start_date, end_date, registration_deadline, fees, total_seating_capacity, target_number_registrations, eid);

    current_sid := 1;
    FOR i IN 1..array_length(session_date, 1)
    LOOP
        SELECT Available_Instructors.eid INTO current_available_instructor
        FROM find_instructors(course_id, session_date[i], session_start_hour[i]) Available_Instructors
        LIMIT 1;

        IF current_available_instructor IS NULL THEN
            RAISE EXCEPTION 'No instructor available for session on % at %00 hours', session_date[i], session_start_hour[i];
        END IF;

        CALL add_session(course_id, launch_date, current_sid, session_date[i], session_start_hour[i], room_id[i], current_available_instructor);
        current_sid := current_sid + 1;
    END LOOP;
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

-- 15
CREATE OR REPLACE FUNCTION get_available_course_offerings()
RETURNS TABLE (title TEXT, area TEXT, launchDate DATE, start_date DATE, end_date DATE, registration_deadline DATE, fees INT, remaining_seats INT)
AS $$
BEGIN
    RETURN QUERY
    SELECT Courses.title, Courses.area, Offerings.launch_date, Offerings.start_date, Offerings.end_date, Offerings.registration_deadline, Offerings.fees, 
        (Offerings.seating_capacity - coalesce(Registrations.num_registrations, 0) - coalesce(Redemptions.num_redemptions, 0)) AS remaining_seats
    FROM Courses NATURAL JOIN Offerings
        NATURAL LEFT OUTER JOIN (SELECT course_id, launch_date, count(*)::INT AS num_registrations 
                        FROM Registers GROUP BY course_id, launch_date) AS Registrations
        NATURAL LEFT OUTER JOIN (SELECT course_id, launch_date, count(*)::INT AS num_redemptions 
                        FROM Redeems GROUP BY course_id, launch_date) AS Redemptions
        NATURAL LEFT OUTER JOIN (SELECT course_id, launch_date, count(*)::INT AS num_cancellations 
                        FROM Redeems GROUP BY course_id, launch_date) AS Cancellations
    WHERE Offerings.registration_deadline >= NOW()
    AND (COALESCE(Registrations.num_registrations, 0) + COALESCE(Redemptions.num_redemptions, 0) - COALESCE(Cancellations.num_cancellations, 0)) < Offerings.seating_capacity
    ORDER BY Offerings.registration_deadline, Courses.title;
END
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

-- 20.
CREATE OR REPLACE PROCEDURE cancel_registration (cust_id INT, course_id INT, launch_date date) 
AS $$
DECLARE
    cust_cc_number char(20);
    cancelled_sid INT;
BEGIN
    SELECT cc_number INTO cust_cc_number
    FROM Owns
    WHERE Owns.cust_id = cancel_registration.cust_id
    ORDER BY from_date desc
    LIMIT 1;

    SELECT sid
    INTO cancelled_sid
    FROM Registers
    WHERE Registers.launch_date = cancel_registration.launch_date
        AND Registers.course_id = cancel_registration.course_id
        AND Registers.cc_number = cust_cc_number
    ORDER BY reg_date desc
    LIMIT 1;

    IF cancelled_sid IS NULL THEN 
        SELECT sid
        INTO cancelled_sid
        FROM Redeems
        WHERE Redeems.launch_date = cancel_registration.launch_date
            AND Redeems.course_id = cancel_registration.course_id
            AND Redeems.cc_number = cust_cc_number
        ORDER BY redeem_date desc
        LIMIT 1;
    END IF;

    IF cancelled_sid IS NULL THEN
        RAISE EXCEPTION 'No valid sid matches the course offering and cust_id.';
    END IF;

    INSERT INTO Cancels (cancel_date, sid, course_id, launch_date, cust_id, refund_amt, package_credit)
    VALUES (NOW()::date, cancelled_sid, cancel_registration.course_id,
        cancel_registration.launch_date, cancel_registration.cust_id, 0, 0);
END;
$$ LANGUAGE plpgsql;

-- 21.
/*
Note: Extra parameter launch_date is added because the course_id and sid alone are insufficient to identify a particular Session.
For example, if the same Course has two offerings running concurrently, where each offering has some session with the same id.
*/
CREATE OR REPLACE PROCEDURE update_instructors (_course_id INT, _sid INT, _new_eid INT, _launch_date DATE)
AS $$
DECLARE
    _session_date DATE;
    _session_start_time INT;
    _session_end_time INT;
BEGIN
    -- check if the session, given by the course_id and sid even exists
    IF (SELECT COUNT(*) FROM Sessions S WHERE S.course_id = _course_id and S.sid = _sid and S.launch_date = _launch_date) = 0 THEN
        RAISE EXCEPTION 'Course id or session id is invalid.';
    END IF;

    -- check that the course session has not yet started
    SELECT S.session_date INTO _session_date FROM Sessions S WHERE S.course_id = _course_id and S.sid = _sid and S.launch_date = _launch_date;
    SELECT S.start_time INTO _session_start_time FROM Sessions S WHERE S.course_id = _course_id and S.sid = _sid and S.launch_date = _launch_date;
    SELECT S.end_time INTO _session_end_time FROM Sessions S WHERE S.course_id = _course_id and S.sid = _sid and S.launch_date = _launch_date;
    IF (NOW()::DATE > _session_date::DATE) OR (NOW() = _session_date AND EXTRACT(HOUR from current_time) >= _session_start_time) THEN
        RAISE EXCEPTION 'Session has already started or is over.';
    END IF;

    -- check that new eid is not the same as old eid
    IF _new_eid = (SELECT S.eid FROM Sessions S WHERE S.course_id = _course_id and S.sid = _sid and S.launch_date = _launch_date) THEN
        RAISE EXCEPTION 'This Instructor is already conducting this session.';
    END IF;

    -- Check if the instructor is in the list of instructors that can be assigned to the course session.
    IF _new_eid IN (SELECT eid FROM find_instructors(_course_id, _session_date, _session_start_time)) THEN
        UPDATE Sessions SET eid = _new_eid WHERE sid = _sid AND course_id = _course_id AND launch_date = _launch_date;
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

    IF NOW() < session_start_date OR (NOW() = session_start_date AND EXTRACT(HOUR from current_time) < session_start_time) THEN
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

    IF NOW() < session_start_date OR (NOW() = session_start_date AND EXTRACT(HOUR from current_time) < session_start_time) THEN
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
        ELSE
            IF NOT valid_instructor THEN
                RAISE EXCEPTION 'Invalid Instructor';
            ELSE
                RAISE EXCEPTION 'Invalid Room';
            END IF;
        END IF;
    ELSE
        RAISE EXCEPTION 'Registration is over';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 25.
CREATE OR REPLACE FUNCTION pay_salary()
RETURNS TABLE(eid INT, name text, status text, num_work_days INT, num_work_hours INT, hourly_rate INT, monthly_salary INT, salary_paid INT)
AS $$
DECLARE
    curs CURSOR FOR (SELECT * FROM Employees ORDER BY eid ASC);
    r RECORD;
    curr_month_days INT;
    first_work_day INT;
    last_work_day INT;
BEGIN
    curr_month_days := DATE_PART('days', DATE_TRUNC('month', NOW()) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL);
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        IF r.eid IN (SELECT Part_time_Emp.eid FROM Part_time_Emp) THEN
            eid := r.eid;
            name := r.name;
            status = 'part-time';
            num_work_days := NULL;
            monthly_salary := NULL;

            SELECT COALESCE(SUM(ST.duration), 0) INTO num_work_hours
            FROM (Sessions NATURAL JOIN Courses) ST
            WHERE ST.eid = r.eid AND
                EXTRACT(MONTH FROM ST.session_date) = EXTRACT(MONTH FROM NOW());

            SELECT PTE.hourly_rate INTO hourly_rate 
            FROM Part_time_Emp PTE 
            WHERE PTE.eid = r.eid;

            salary_paid := hourly_rate * num_work_hours;

        ELSE
            eid := r.eid;
            name := r.name;
            status = 'full-time';
            num_work_hours := NULL;
            hourly_rate := NULL;

            IF EXTRACT(MONTH FROM r.join_date) = EXTRACT(MONTH FROM NOW()) THEN
                first_work_day := CAST(EXTRACT(DAY FROM r.join_date) AS INTEGER);
            ELSE
                first_work_day := 1;
            END IF;

            IF r.depart_date IS NOT NULL AND EXTRACT(MONTH FROM r.depart_date) = EXTRACT(MONTH FROM NOW()) THEN
                last_work_day := CAST(EXTRACT(DAY FROM r.depart_date) AS INTEGER);
            ELSE
                last_work_day := curr_month_days;
            END IF;
            num_work_days := last_work_day - first_work_day + 1;
            
            SELECT FTE.monthly_salary INTO monthly_salary
            FROM Full_time_Emp FTE
            WHERE FTE.eid = r.eid;

            salary_paid := CAST(((num_work_days / curr_month_days) * monthly_salary) AS INTEGER);
        END IF;

        INSERT INTO Pay_slips (eid, payment_date, amount, num_work_hours, num_work_days)
        VALUES (eid, NOW(), salary_paid, num_work_hours, num_work_days);
        
        RETURN NEXT;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-- 26.
CREATE OR REPLACE FUNCTION promote_courses ()
RETURNS TABLE (customer_id INT, customer_name text, course_area text, courseID INT, course_title text, offering_launch_date DATE, reg_deadline DATE, course_fees INT)
AS $$
BEGIN
    RETURN QUERY
    WITH Inactive_customers AS (
        SELECT cust_id, cust_name, cc_number
        FROM Customers NATURAL JOIN Owns
        EXCEPT
        SELECT cust_id, cust_name, cc_number
        FROM (Customers NATURAL JOIN Owns) NATURAL JOIN Registers
        GROUP BY cust_id, cust_name, cc_number
        HAVING MAX(reg_date) >= (NOW() - INTERVAL '6 MONTHS')
        EXCEPT
        SELECT cust_id, cust_name, cc_number
        FROM (Customers NATURAL JOIN Owns) NATURAL JOIN Redeems
        GROUP BY cust_id, cust_name, cc_number
        HAVING MAX(redeem_date) >= (NOW() - INTERVAL '6 MONTHS')
    ),
    Customers_with_interests AS (
        SELECT * 
        FROM (
            SELECT cust_id, cust_name, area, ROW_NUMBER() OVER (
                PARTITION BY cust_id, cust_name
                ORDER BY cust_id, cust_name, reg_date
            ) AS row_index
            FROM (
                SELECT cust_id, cust_name, area, reg_date
                FROM Inactive_customers NATURAL JOIN (Courses NATURAL JOIN Registers)
                UNION
                SELECT cust_id, cust_name, area, redeem_date as reg_date
                FROM Inactive_customers NATURAL JOIN (Courses NATURAL JOIN Redeems)              
            ) CR
        ) CR2
        WHERE row_index <= 3
    ),
    Customers_without_interests AS (
        SELECT cust_id, cust_name
        FROM Inactive_customers
        EXCEPT
        SELECT cust_id, cust_name
        FROM Customers_with_interests
    ),
    Customers_interests AS (
        SELECT DISTINCT cust_id, cust_name, area 
        FROM Customers_with_interests
        UNION
        SELECT DISTINCT cust_id, cust_name, area
        FROM Customers_without_interests, Course_Areas
    ),
    Available_offerings AS (
        SELECT *
        FROM get_available_course_offerings()
    )
    SELECT cust_id, cust_name, area, course_id, title, launchDate, registration_deadline, fees
    FROM Customers_interests NATURAL LEFT JOIN (Courses NATURAL JOIN Available_offerings)
    ORDER BY cust_id, registration_deadline;
END;
$$ LANGUAGE plpgsql;

-- 27.
CREATE OR REPLACE FUNCTION top_packages (N INT)
RETURNS TABLE (package_id INT, num_free_registrations INT, price INT, sale_start_date DATE, sale_end_date DATE, num_sold INT)
AS $$
DECLARE
    curs CURSOR FOR (
        SELECT P.package_id, P.num_free_registrations, P.price, P.sale_start_date, P.sale_end_date, (
            SELECT COUNT(*) 
            FROM Buys B
            WHERE B.package_id = P.package_id
        ) AS num_sold
        FROM Course_packages P
        WHERE EXTRACT(YEAR FROM P.sale_start_date) = EXTRACT(YEAR FROM NOW())
        ORDER BY num_sold DESC, P.price DESC
    );
    r RECORD;
    counter INT;
    prev_num_sold INT;
BEGIN
    counter := 0;
    OPEN curs;
    LOOP
        FETCH curs into r;
        EXIT WHEN NOT FOUND;
        IF counter < N OR r.num_sold = prev_num_sold THEN
            counter := counter + 1;
            prev_num_sold := r.num_sold;
            package_id := r.package_id;
            num_free_registrations := r.num_free_registrations;
            price := r.price;
            sale_start_date := r.sale_start_date;
            sale_end_date := r.sale_end_date;
            num_sold := r.num_sold;
            RETURN NEXT;
        ELSE
            EXIT;
        END IF;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

--28.
CREATE OR REPLACE FUNCTION popular_courses() 
RETURNS TABLE (course_id INT, title TEXT, area TEXT, num_offerings INT, num_regs_latest_offering INT) AS $$
DECLARE
    curs CURSOR FOR (
        WITH registrations AS (
            SELECT rg.course_id, rg.launch_date, count(*) AS num_registrations
            FROM Registers rg
            GROUP BY rg.course_id, rg.launch_date
        ),
        redemptions AS (
            SELECT rd.course_id, rd.launch_date, count(*) AS num_redemptions
            FROM Redeems rd
            GROUP BY rd.course_id, rd.launch_date
        ),
        cancellations AS (
            SELECT c.course_id, c.launch_date, count(*) AS num_cancellations
            FROM Cancels c
            GROUP BY c.course_id, c.launch_date
        ),
        total_registrations AS (
            SELECT c.course_id, c.title, c.area, o1.launch_date
            FROM Courses c NATURAL LEFT OUTER JOIN Offerings o1
            WHERE EXTRACT(YEAR FROM o1.start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND (
                SELECT count(o2.launch_date) > 2
                FROM Offerings o2
                WHERE c.course_id = o2.course_id
            )
        )
        SELECT total_registrations.course_id, total_registrations.title, total_registrations.area, total_registrations.launch_date, COALESCE(registrations.num_registrations, 0) + COALESCE(redemptions.num_redemptions, 0) - COALESCE(cancellations.num_cancellations, 0) AS total_registrations
        FROM total_registrations 
            NATURAL LEFT OUTER JOIN registrations
            NATURAL LEFT OUTER JOIN redemptions
            NATURAL LEFT OUTER JOIN cancellations
        ORDER BY total_registrations.course_id, total_registrations.launch_date
    );
    current_rec RECORD;
    previous_rec RECORD;
    is_popular BOOLEAN;
    num_offerings INT;
BEGIN
    num_offerings := 1;
    is_popular := TRUE;

    OPEN curs;
    FETCH curs INTO previous_rec;
    LOOP
        FETCH curs INTO current_rec;
        EXIT WHEN NOT FOUND;
        
        IF previous_rec.course_id = current_rec.course_id THEN
            IF previous_rec.total_registrations >= current_rec.total_registrations THEN
                is_popular := FALSE;
            ELSE
                num_offerings := num_offerings + 1;
            END IF;
        ELSIF previous_rec.course_id <> current_rec.course_id THEN
            IF is_popular = TRUE THEN
                course_id := previous_rec.course_id;
                title := previous_rec.title;
                area := previous_rec.area;
                num_offerings := num_offerings;
                num_regs_latest_offering := previous_rec.total_registrations;
                RETURN NEXT;
                num_offerings := 1;
            ELSE
                is_popular := TRUE;
                num_offerings := 1;
            END IF;
        END IF;
        previous_rec := current_rec;
    END LOOP;
    
    IF is_popular = TRUE THEN
        popular_courses.course_id := previous_rec.course_id;
        popular_courses.title := previous_rec.title;
        popular_courses.area := previous_rec.area;

        popular_courses.num_offerings := num_offerings;
        popular_courses.num_regs_latest_offering := previous_rec.total_registrations;
        RETURN NEXT;
    END IF;

    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-- 29.
CREATE OR REPLACE FUNCTION view_summary_report (N INT)
RETURNS TABLE (month_year text, total_salary INT, total_sales INT, total_fees INT, total_refund INT, total_redeems INT)
AS $$
DECLARE
    curs CURSOR FOR (
        SELECT generate_series AS m_y
        FROM generate_series ((NOW() - (N - 1) * INTERVAL '1 MONTH')::timestamp, NOW()::timestamp, '1 MONTH')
        ORDER BY m_y DESC
    );
    r RECORD;
    curs_month INT;
    curs_year INT;
BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        month_year := to_char(r.m_y, 'Month YYYY');
        curs_month := DATE_PART('MONTH', r.m_y);
        curs_year := DATE_PART('YEAR', r.m_y);

        SELECT COALESCE(SUM(Salary.amount), 0) INTO total_salary
        FROM (
            SELECT PS.amount, 
                   DATE_PART('MONTH', PS.payment_date) AS payment_month, 
                   DATE_PART('YEAR', PS.payment_date) AS payment_year
            FROM Pay_slips PS
        ) Salary
        WHERE Salary.payment_month = curs_month AND Salary.payment_year = curs_year;

        SELECT COALESCE(SUM(Sales.price), 0) INTO total_sales
        FROM (
            SELECT BCP.price, 
                   DATE_PART('MONTH', BCP.transaction_date) AS transaction_month, 
                   DATE_PART('YEAR', BCP.transaction_date) AS transaction_year
            FROM (Buys NATURAL JOIN Course_packages) BCP
        ) Sales
        WHERE Sales.transaction_month = curs_month AND Sales.transaction_year = curs_year;
    
        SELECT COALESCE(SUM(Registrations.fees), 0) INTO total_fees
        FROM (
            SELECT RO.fees, 
                   DATE_PART('MONTH', RO.reg_date) AS reg_month, 
                   DATE_PART('YEAR', RO.reg_date) AS reg_year
            FROM (Registers NATURAL JOIN Offerings) RO
        ) Registrations
        WHERE Registrations.reg_month = curs_month AND Registrations.reg_year = curs_year;

        SELECT COALESCE(SUM(Refunds.refund_amt), 0) INTO total_refund
        FROM (
            SELECT C.refund_amt, 
                   DATE_PART('MONTH', C.cancel_date) AS cancel_month, 
                   DATE_PART('YEAR', C.cancel_date) AS cancel_year
            FROM Cancels C
        ) Refunds
        WHERE Refunds.cancel_month = curs_month AND Refunds.cancel_year = curs_year;

        SELECT COALESCE(COUNT(*), 0) INTO total_redeems
        FROM (
            SELECT DATE_PART('MONTH', RD.redeem_date) AS redeem_month, 
                   DATE_PART('YEAR', RD.redeem_date) AS redeem_year
            FROM Redeems RD
        ) Redemptions
        WHERE Redemptions.redeem_month = curs_month AND Redemptions.redeem_year = curs_year;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 30.
CREATE OR REPLACE FUNCTION compute_net_registration_fees (in_eid INT) 
RETURNS TABLE(course_id INT, fee INT) 
AS $$
DECLARE
    curs CURSOR for (
        SELECT C.course_id 
        FROM Courses C, Course_areas CA 
        WHERE (CA.area = C.area) AND (CA.eid = in_eid)
    );
    re RECORD;
BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO re;
        EXIT WHEN NOT FOUND;

        course_id := re.course_id;
        fee := (SELECT coalesce((
            SELECT SUM(O.fees)
            FROM Offerings O, Sessions S, Registers R
            WHERE (O.course_id = re.course_id)
            AND ((SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW())))
            AND (S.course_id = O.course_id)
            AND (S.launch_date = O.launch_date)
            AND (R.sid = S.sid)), 0)
        )
        - (SELECT coalesce((
            SELECT SUM(CL.refund_amt)
            FROM Offerings O, Sessions S, Cancels CL
            WHERE (O.course_id = re.course_id)
            AND ((SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW())))
            AND (S.course_id = O.course_id)
            AND (S.launch_date = O.launch_date)
            AND (CL.sid = S.sid)), 0)
        )
        + (SELECT coalesce((
            SELECT SUM(CP.price / CP.num_free_registrations)
            FROM Offerings O, Sessions S, Course_packages CP, Redeems R
            WHERE (O.course_id = re.course_id)
            AND ((SELECT DATE_PART('year', O.end_date)) = (SELECT DATE_PART('year', NOW())))
            AND (S.course_id = O.course_id)
            AND (S.launch_date = O.launch_date)
            AND (R.sid = S.sid)
            AND (R.package_id = CP.package_id)), 0)
        );
        RETURN NEXT;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

create or replace function view_manager_report() returns table(mname text, num_course_areas int, num_course_offerings int, total_net_fee integer, offering_title text) as $$
declare
  curs1 cursor for (select E.name, E.eid from Managers M, Employees E where M.eid = E.eid order by E.name);
  r record;
  n int;
begin
  open curs1;
  loop
    fetch curs1 into r;
    exit when not found;
    n := (with X as (select * from compute_net_registration_fees(r.eid))
          select count(*)
          from Courses C, X
          where (C.course_id = X.course_id)
          and (X.fee = (select MAX(fee) from X)));
    if n = 0 then
      n := 1;
    end if;
    loop
      exit when n = 0;
      mname := r.name;
      num_course_areas := (select count(*)
                           from Course_areas C
                           where C.eid = r.eid);
      num_course_offerings := (select count(*)
                               from Course_areas CA, Courses C, Offerings O
                               where (CA.eid = r.eid)
                               and (C.area = CA.area)
                               and (O.course_id = C.course_id)
                               and ((select DATE_PART('year', O.end_date)) = (select DATE_PART('year', NOW()))) );
      total_net_fee := (with X as (select * from compute_net_registration_fees(r.eid))
                        select SUM(X.fee)
                        from X);

      offering_title := (with X as (select * from compute_net_registration_fees(r.eid))
                         select C.title
                         from Courses C, X
                         where (C.course_id = X.course_id)
                         and (X.fee = (select MAX(fee) from X))
                         offset (n - 1)
                         limit 1);
      return next;
      n := n - 1;
    end loop;

  end loop;
  close curs1;
end;
$$ language plpgsql;

-- 30
CREATE OR REPLACE FUNCTION view_manager_report_2() 
RETURNS TABLE(name TEXT, num_areas INTEGER, num_offerings INTEGER, total_registration_fees INT, titles TEXT[]) AS $$
DECLARE
    curs CURSOR FOR (
        SELECT Manager.eid, Manager.name 
        FROM (Managers NATURAL JOIN Employees) Manager
        ORDER BY Manager.name ASC
        );
    r RECORD;
    registration_fees INTEGER;
    redemption_fees INTEGER;
BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        name := r.name;

        -- Count areas managed
        SELECT COALESCE(COUNT(*), 0)
        INTO num_areas
        FROM Course_areas CA
        WHERE r.eid = CA.eid;

        -- Count course offerings managed (that ended this year)
        SELECT COALESCE(COUNT(*), 0) INTO num_offerings 
        FROM (Courses 
            NATURAL JOIN Offerings 
            NATURAL JOIN Course_areas) co
        WHERE r.eid = co.eid
        AND EXTRACT(YEAR FROM co.end_date) = EXTRACT(YEAR FROM CURRENT_DATE);

        -- Calculate nett registration fees
        SELECT COALESCE(SUM(reg.fees), 0) INTO registration_fees
        FROM (Registers 
            NATURAL JOIN Courses 
            NATURAL JOIN Offerings 
            NATURAL JOIN Course_areas) reg
        WHERE r.eid = reg.eid
        AND EXTRACT(YEAR FROM reg.end_date) = EXTRACT(YEAR FROM CURRENT_DATE);
        
        -- Calculate nett redemption fees
        WITH PackagePrices AS(
            SELECT package_id, FLOOR(price / num_free_registrations) AS price_per_session 
            FROM Course_packages)        
        SELECT COALESCE(SUM(red.price_per_session), 0) INTO redemption_fees
        FROM (Redeems 
            NATURAL JOIN PackagePrices
            NATURAL JOIN Courses 
            NATURAL JOIN Course_areas 
            NATURAL JOIN Offerings) red
        WHERE r.eid = red.eid
        AND EXTRACT(YEAR FROM red.end_date) = EXTRACT(YEAR FROM CURRENT_DATE);

        total_registration_fees := registration_fees + redemption_fees;

        WITH
        RegistrationFees AS(
            SELECT reg.course_id, reg.launch_date, COALESCE(SUM(reg.fees), 0) AS co_registration_fees
            FROM (Registers 
                NATURAL JOIN Offerings 
                NATURAL JOIN Courses 
                NATURAL JOIN Course_areas) reg
            WHERE r.eid = reg.eid
            AND EXTRACT(YEAR FROM reg.end_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            GROUP BY reg.course_id, reg.launch_date),
        PackagePrices AS(
            SELECT package_id, FLOOR (price / num_free_registrations) AS price_per_session 
            FROM Course_packages),
        RedemptionFees AS(
            SELECT red.course_id, red.launch_date, COALESCE(SUM(red.price_per_session), 0) AS co_redemption_fees
            FROM (Redeems
                NATURAL JOIN PackagePrices
                NATURAL JOIN Courses
                NATURAL JOIN Course_areas
                NATURAL JOIN Offerings) red
            WHERE r.eid = red.eid
            AND EXTRACT(YEAR FROM red.end_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            GROUP BY red.course_id, red.launch_date),
        TotalRegistrationFees AS(
            SELECT course_id, launch_date, co_registration_fees + co_redemption_fees AS co_total_fees
            FROM RegistrationFees 
                NATURAL JOIN RedemptionFees)
        SELECT ARRAY(
            SELECT C1.title
            FROM (TotalRegistrationFees
                NATURAL JOIN Courses) C1
            WHERE C1.co_total_fees = (
                SELECT MAX(C2.co_total_fees) 
                FROM TotalRegistrationFees C2)
        ) INTO titles;
        RETURN NEXT;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-- For Testing
-- CALL add_employee('Employee1', 'Singapore', '98385373', 'employee1@u.nus.edu', '300', NULL, '2021-01-02', 'administrator', '{}');
-- CALL add_employee('Employee2', 'Singapore', '88984232', 'employee2@u.nus.edu', NULL, '10', '2021-02-02', 'instructor', '{}');
-- CALL add_customer('Joel', 'CCK', '82345678', 'joel@joel.com', '1234123412341234', 123, '2021-01-01');
-- CALL add_course_package('TESTING', 10, 5, '2021-01-01', '2021-05-05');
-- CALL buy_course_package(1, 1);
-- SELECT get_my_course_package(1);
-- CALL add_course('Advance Team Project Management', 'Advanced module on project management in the real world.', 'project management', 1);
-- call add_course_offering(3, 200, '2021-04-01', '2021-05-03', 100, 11, '{"2021-06-07"}', '{20}', '{6}');
