-- Triggers
-- Executed after data.sql to only enforce constraints after seed data is imported

-- Employee either FT or PT

CREATE OR REPLACE FUNCTION employee_ftpt_constraint() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.eid NOT IN (SELECT eid FROM Full_time_Emp)
    AND NEW.eid NOT IN (SELECT eid FROM Part_time_Emp) THEN
        RAISE EXCEPTION 'New employee must be either part-time or full-time.';
    END IF;
    IF NEW.eid IN (SELECT eid FROM Full_time_Emp)
    AND NEW.eid IN (SELECT eid FROM Part_time_Emp) THEN
        RAISE EXCEPTION 'New employee cannot be both part-time and full-time.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER employee_ftpt_constraint_trigger AFTER
INSERT
OR
UPDATE ON Employees DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION employee_ftpt_constraint();

-- FT employee either administrator, manager or FT instructor

CREATE OR REPLACE FUNCTION full_time_employee_constraint() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.eid NOT IN (SELECT eid FROM Administrators)
    AND NEW.eid NOT IN (SELECT eid FROM Managers)
    AND NEW.eid NOT IN (SELECT eid FROM Full_time_instructors) THEN
        RAISE EXCEPTION 'A full-time employee must only be either a administrator, a manager or a full-time instructor.';
    END IF;
    IF (NEW.eid IN (SELECT eid FROM Administrators)
        AND NEW.eid IN (SELECT eid FROM Managers))
    OR (NEW.eid IN (SELECT eid FROM Administrators)
        AND NEW.eid IN (SELECT eid FROM Full_time_instructors))
    OR (NEW.eid IN (SELECT eid FROM Managers)
        AND NEW.eid IN (SELECT eid FROM Full_time_instructors))
    THEN
        RAISE EXCEPTION 'A full-time employee must only be either a administrator, a manager, or a full-time instructor.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER full_time_employee_constraint_trigger AFTER
INSERT
OR
UPDATE ON Full_time_Emp DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION full_time_employee_constraint();

-- PT employee can only be PT instructor

CREATE OR REPLACE FUNCTION part_time_employee_constraint() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.eid NOT IN (SELECT eid FROM Part_time_instructors) THEN
        RAISE EXCEPTION 'A part-time employee must only be an instructor.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER part_time_emloyee_constraint_trigger AFTER
INSERT
OR
UPDATE ON Part_time_Emp DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION part_time_employee_constraint();

-- Instructors can only be either FT or PT

CREATE OR REPLACE FUNCTION instructors_constraint() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.eid NOT IN (SELECT eid FROM Full_time_instructors)
    AND NEW.eid NOT IN (SELECT eid FROM Part_time_instructors) THEN
        RAISE EXCEPTION 'An instructor must only be either a full-time or a part-time instructor.';
    END IF;
    IF NEW.eid IN (SELECT eid FROM Full_time_instructors)
    AND NEW.eid IN (SELECT eid FROM Part_time_instructors) THEN
        RAISE EXCEPTION 'An instructor cannot be both full-time and part-time.';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE CONSTRAINT TRIGGER instructors_constraint_trigger AFTER
INSERT
OR
UPDATE ON Instructors DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION instructors_constraint();


CREATE OR REPLACE FUNCTION disable_owns_update_delete() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Updating or deleting of Owns is not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER disable_owns_update_delete_trigger
BEFORE
UPDATE
OR
DELETE ON Owns
FOR EACH ROW EXECUTE FUNCTION disable_owns_update_delete();


CREATE OR REPLACE FUNCTION credit_cards_owns_key_constraint() RETURNS TRIGGER AS $$
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
BEFORE
INSERT ON Owns
FOR EACH ROW EXECUTE FUNCTION credit_cards_owns_key_constraint();


CREATE OR REPLACE FUNCTION owns_participation_constraint() RETURNS TRIGGER AS $$
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
BEFORE
UPDATE
OR
DELETE ON Owns
FOR EACH ROW EXECUTE FUNCTION owns_participation_constraint();


CREATE OR REPLACE FUNCTION credit_cards_participation_constraint() RETURNS TRIGGER AS $$
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


CREATE CONSTRAINT TRIGGER credit_cards_participation_constraint_trigger AFTER
INSERT
OR
UPDATE ON Credit_cards DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_participation_constraint();


CREATE OR REPLACE FUNCTION customers_participation_constraint() RETURNS TRIGGER AS $$
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


CREATE CONSTRAINT TRIGGER customers_participation_constraint_trigger AFTER
INSERT
OR
UPDATE ON Customers DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION customers_participation_constraint();

-- TODO: What if customer change credit card?

CREATE OR REPLACE FUNCTION at_most_one_active_or_partially_active_package() RETURNS TRIGGER AS $$
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
        AND Sessions.session_date - NOW()::date >= 7;

    IF num_cancellable_sessions >= 1 THEN
        RAISE EXCEPTION 'There is a partially active course package.';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER at_most_one_active_or_partially_active_package_trigger
BEFORE
INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION at_most_one_active_or_partially_active_package();


CREATE OR REPLACE FUNCTION check_seating_capacity() RETURNS TRIGGER AS $$
DECLARE
    num_registered INT;
    num_redeemed INT;
    num_cancelled INT;
    seating_cap INT;
BEGIN
    SELECT COUNT(*)
    INTO num_registered
    FROM Registers
    WHERE Registers.launch_date = NEW.launch_date
        AND Registers.course_id = NEW.course_id
        AND Registers.sid = NEW.sid;

    SELECT COUNT(*)
    INTO num_redeemed
    FROM Redeems
    WHERE Redeems.launch_date = NEW.launch_date
        AND Redeems.course_id = NEW.course_id
        AND Redeems.sid = NEW.sid;

    SELECT COUNT(*)
    INTO num_cancelled
    FROM Cancels
    WHERE Cancels.launch_date = NEW.launch_date
        AND Cancels.course_id = NEW.course_id
        AND Cancels.sid = NEW.sid;

    SELECT seating_capacity
    INTO seating_cap
    FROM Sessions NATURAL JOIN Rooms
    WHERE Sessions.launch_date = NEW.launch_date
        AND Sessions.course_id = NEW.course_id
        AND Sessions.sid = NEW.sid;

    IF num_registered + num_redeemed - num_cancelled >= seating_cap THEN
        RAISE EXCEPTION 'Session has already reached maximum capacity.';
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_seating_capacity_registers_trigger
BEFORE
INSERT
OR
UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION check_seating_capacity();


CREATE TRIGGER check_seating_capacity_redeems_trigger
BEFORE
INSERT
OR
UPDATE ON Redeems
FOR EACH ROW EXECUTE FUNCTION check_seating_capacity();


CREATE OR REPLACE FUNCTION registered_redeemed_before_cancel() RETURNS TRIGGER AS $$
DECLARE
    cust_cc_number char(20);
    num_registered INT;
    latest_registered_date date;
    course_fees INT;
    num_redeemed INT;
    latest_redeemed_date date;
    buys_transaction_date date;
    buys_package_id INT;

    cancelled_session_date date;
BEGIN
    NEW.cancel_date := NOW()::date;
    NEW.refund_amt := 0;
    NEW.package_credit := 0;

    SELECT cc_number INTO cust_cc_number
    FROM Owns
    WHERE Owns.cust_id = NEW.cust_id
    ORDER BY from_date desc
    LIMIT 1;

    SELECT COUNT(*), MAX(reg_date)
    INTO num_registered, latest_registered_date
    FROM Registers
    WHERE Registers.sid = NEW.sid
        AND Registers.course_id = NEW.course_id
        AND Registers.launch_date = NEW.launch_date
        AND Registers.cc_number = cust_cc_number;

    SELECT COUNT(*), MAX(redeem_date)
    INTO num_redeemed, latest_redeemed_date
    FROM Redeems
    WHERE Redeems.sid = NEW.sid
        AND Redeems.course_id = NEW.course_id
        AND Redeems.launch_date = NEW.launch_date
        AND Redeems.cc_number = cust_cc_number;
    IF num_registered + num_redeemed = 0 THEN
        RAISE EXCEPTION 'Session has not been registered or redeemed by user.';
        RETURN NULL;
    END IF;

    SELECT session_date
    INTO cancelled_session_date
    FROM Sessions s
    WHERE s.sid = NEW.sid
        AND s.course_id = NEW.course_id
        AND s.launch_date = NEW.launch_date;

    IF num_redeemed == 0 THEN -- Registered
        IF cancelled_session_date - NEW.cancel_date >= 7 THEN
            SELECT o.fees
            INTO course_fees
            FROM Sessions s JOIN Offerings o
                ON s.launch_date = o.launch_date
                    AND s.course_id = o.course_id
            WHERE s.sid = NEW.sid
                AND s.course_id = NEW.course_id
                AND s.launch_date = NEW.launch_date;

            NEW.refund_amt := 0.9 * course_fees;
        END IF;
    ELSIF num_registered == 0 THEN -- Redeemed
        IF cancelled_session_date - NEW.cancel_date >= 7 THEN
            NEW.package_credit := 1;

            SELECT transaction_date, package_id
            INTO buys_transaction_date, buys_package_id
            FROM Redeems
            WHERE Redeems.sid = NEW.sid
                AND Redeems.course_id = NEW.course_id
                AND Redeems.launch_date = NEW.launch_date
                AND Redeems.cc_number = cust_cc_number
                AND Redeems.redeem_date = latest_redeemed_date;

            UPDATE Buys
            SET Buys.num_remaining_registrations = Buys.num_remaining_registrations + 1
            WHERE Buys.transaction_date = buys_transaction_date
                AND Buys.cc_number = cust_cc_number
                AND Buys.package_id = buys_package_id;
        END IF;
    ELSIF latest_registered_date > latest_redeemed_date THEN -- Registered

    ELSE -- Redeemed
        IF cancelled_session_date - NEW.cancel_date >= 7 THEN
            NEW.package_credit := 1;

            SELECT transaction_date, package_id
            INTO buys_transaction_date, buys_package_id
            FROM Redeems
            WHERE Redeems.sid = NEW.sid
                AND Redeems.course_id = NEW.course_id
                AND Redeems.launch_date = NEW.launch_date
                AND Redeems.cc_number = cust_cc_number
                AND Redeems.redeem_date = latest_redeemed_date;

            UPDATE Buys
            SET Buys.num_remaining_registrations = Buys.num_remaining_registrations + 1
            WHERE Buys.transaction_date = buys_transaction_date
                AND Buys.cc_number = cust_cc_number
                AND Buys.package_id = buys_package_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER registered_redeemed_before_cancel_trigger
BEFORE
INSERT ON Cancels
FOR EACH ROW EXECUTE FUNCTION registered_redeemed_before_cancel();


CREATE OR REPLACE FUNCTION disable_cancels_update_or_delete() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Updating or deleting of Cancels is not allowed.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER disable_cancels_update_or_delete_trigger
BEFORE
UPDATE
OR
DELETE ON Cancels
FOR EACH ROW EXECUTE FUNCTION disable_cancels_update_or_delete();


CREATE OR REPLACE FUNCTION sequential_sid() RETURNS TRIGGER AS $$
DECLARE
    prev_max_sid INT;
BEGIN
    SELECT COALESCE(MAX(sid), 0) INTO prev_max_sid
    FROM Sessions
    WHERE Sessions.course_id = NEW.course_id AND Sessions.launch_date = NEW.launch_date;

    NEW.sid := prev_max_sid + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER sequential_sid_trigger
BEFORE
INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION sequential_sid();
