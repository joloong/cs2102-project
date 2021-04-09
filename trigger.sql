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