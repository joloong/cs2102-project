-- CS2102 Project Team 41 data.sql

DELETE FROM Rooms;
DELETE FROM Employees;
DELETE FROM Part_time_Emp;
DELETE FROM Full_time_Emp;
DELETE FROM Instructors;
DELETE FROM Part_time_instructors;
DELETE FROM Full_time_instructors;
DELETE FROM Administrators;
DELETE FROM Course_areas;
DELETE FROM Specializes;
DELETE FROM Managers;
DELETE FROM Pay_slips;
DELETE FROM Customers;
DELETE FROM Credit_cards;
DELETE FROM Owns;
DELETE FROM Course_packages;
DELETE FROM Buys;
DELETE FROM Courses;
DELETE FROM Offerings;
DELETE FROM Sessions;
DELETE FROM Registers;
DELETE FROM Redeems;
DELETE FROM Cancels;

/*
INSERT INTO Credit_cards (cc_number, cvv, expiry_date) VALUES
(1234567891011121, 123, '2013-06-01');

INSERT INTO Customers (cust_name, address, phone, email) VALUES
('Joel', 'CCK', '81234567', 'joel@cs2102.com');

    eid             SERIAL primary key,
    name            text not null,
    phone           text not null,
    email           text not null,
    join_date       date not null,
    address         text not null,
    depart_date     date
*/

INSERT INTO Employees (eid, name, phone, email, join_date, address, depart_date) VALUES
(1, 'Alice', '90991044', 'alice@cs2102.com', '1999-01-08', '10 Heng Mui Keng Terrace', null),
(2, 'Bob', '90992242', 'bob@cs2102.com', '1999-01-11', '4 Sandilands Lane', null),
(3, 'Charlie', '93391069', 'charlie@cs2102.com', '2019-03-25', 'COM1, School Of Computing', null),
(4, 'Daniel', '99999921', 'daniel@cs2102.com', '2012-04-25', '15 Kent Ridge Drive', null),
(5, 'Esther', '90881044', 'esther@cs2102.com', '2009-02-08', '10 Heng Mui Keng Terrace', null),
(6, 'Frodo', '90944242', 'frodo@cs2102.com', '2001-02-11', '4 Sandilands Lane', null),
(7, 'Gary Manager', '91234554', 'gary@cs2102.com', '2019-03-25', 'The Interlace', null),
(8, 'Hemanshu Manager', '97126111', 'hemanshu@cs2102.com', '2012-04-27', 'Sentosa Cove', null),
(9, 'Firzan Manager', '91234114', 'firzan@cs2102.com', '2019-03-25', 'The Interlace', null),
(10, 'Hodor Manager', '97126001', 'hodor@cs2102.com', '2012-04-27', 'Sentosa Cove', null),
(11, 'Ivan Administrator', '90726766', 'ivan@cs2102.com', '2012-04-27', '1 Geyland Serai', null),
(12, 'Jacob Administrator', '91126711', 'jacob@cs2102.com', '2012-04-27', '29 Buona Vista Drive', null),
(13, 'Kate Administrator', '92234714', 'kate@cs2102.com', '2019-03-25', '3 Adis Road', null),
(14, 'Louis Administrator', '93126701', 'louis@cs2102.com', '2012-04-27', 'Telok Kurau Lorong J', null),
(15, 'Mike Administrator', '94126766', 'mike@cs2102.com', '2012-04-27', 'Telok Kurau Lorong K', null);

INSERT INTO Full_time_Emp (eid, monthly_rate) VALUES
(5, 4000),
(6, 6000),
(7, 4000),
(8, 6000),
(9, 6900),
(10, 7000),
(11, 6000),
(12, 6000),
(13, 6000),
(14, 6000),
(15, 5000);

INSERT INTO Part_time_Emp (eid, hourly_rate) VALUES
(1, 69),
(2, 75),
(3, 40),
(4, 120);

INSERT INTO Managers (eid) VALUES
(7),
(8),
(9),
(10);

INSERT INTO Course_areas (area, eid) VALUES
('database systems', 7),
('parallel computing', 8),
('project management', 9),
('theoretical physics', 10);

INSERT INTO Instructors (eid) VALUES
(1),
(2),
(3),
(4),
(5),
(6);

INSERT INTO Specializes (eid, area) VALUES
(1, 'database systems'),
(2, 'parallel computing'),
(3, 'database systems'),
(4, 'database systems'),
(5, 'project management'),
(6, 'theoretical physics');

INSERT INTO Part_time_instructors (eid) VALUES
(1),
(2),
(3),
(4);

INSERT INTO Full_time_instructors (eid) VALUES
(5),
(6);

INSERT INTO Administrators (eid) VALUES
(11),
(12),
(13),
(14),
(15);

INSERT INTO Courses (course_id, title, duration, area) VALUES
(1, 'CS2102: Database Systems', 2, 'database systems'),
(2, 'CS3223: Database Systems Implementation', 2, 'database systems');

INSERT INTO Offerings (course_id, launch_date, start_date, end_date, registration_deadline, fees, seating_capacity, target_number_registrations, eid) VALUES
(1, '2021-03-10', '2021-08-10', '2021-11-11', '2021-07-25', 1000, 100, 100, 11),
(2, '2021-03-25', '2021-08-10', '2021-11-11', '2021-07-25', 1200, 100, 100, 12);

INSERT INTO Rooms (rid, seating_capacity, location) VALUES
(1, 100, 'LT15'),
(2, 200, 'LT27'),
(3, 20, 'COM1-0101'),
(4, 20, 'COM2-0102'),
(5, 90, 'AS-27'),
(6, 150, 'LT19'),
(7, 15, 'COM1-0201'),
(8, 15, 'COM2-0202'),
(9, 100, 'LT16'),
(10, 69, 'LT69');

/* sid is relative to the course_id */
INSERT INTO Sessions (sid, course_id, launch_date, session_date, start_time, end_time, rid, eid) VALUES
(1, 1, '2021-03-10', '2021-08-10', 14, 16, 1, 4),
(1, 2, '2021-03-25', '2021-08-10', 16, 18, 2, 1);

INSERT INTO Customers (cust_name, address, phone, email) VALUES
('Amy Chen', 'Block 223 Serangoon Avenue 3 #03-42', '93742483', 'amychen@gmail.com'),
('Ben Davids', '1 University Road #01-02', '93753482', 'ben_davids@gmail.com'),
('Charlie Wong', 'Block 13 Woodlands Close #12-33', '89201483', 'charliew@gmail.com'),
('Dawn Lim', 'Block 5 Yishun Street 4 #07-224', '93115481', 'dawn_lim_oo@gmail.com'),
('Evan Ong', 'Block 114 Hougang Street 91 #03-10', '97810030', 'EvanONG@gmail.com'),
('Faizal Ali', 'Block 11 Tampines East Avenue 9 #08-41', '83722420', 'faizalali@gmail.com'),
('Govind Raju', 'Block 9 Serangoon North Avenue 1 #04-01', '89722433', 'govindr@gmail.com'),
('Halimah Wati', 'Block 832 Pasir Ris Street 22 #02-54', '90742284', 'halimahwati@gmail.com'),
('Ivy Lee', '1 Whampoa Street 1 #01-12', '91122485', 'ivysunshine@gmail.com'),
('Johnny Wong', 'Block 33 Yishun Ave 33 #07-123', '81922453', 'johnnywong@gmail.com');


INSERT INTO Credit_cards (cc_number, cvv, expiry_date) VALUES
('4566798466523378', '516', '2028-05-03'),
('4522616717675333', '222', '2024-04-02'),
('4535569466151528', '884', '2022-02-05'),
('4566246626377112', '644', '2026-04-06'),
('4670902211105024', '002', '2029-08-07'),
('4609801005910630', '051', '2025-07-03'),
('4612239980177401', '665', '2022-05-02'),
('4999939288503462', '115', '2024-01-06'),
('4628987119585235', '012', '2028-02-01'),
('4889029092342005', '143', '2026-03-05');

INSERT INTO Owns (cc_number, cust_id, from_date) VALUES
('4566798466523378', 1, '2020-03-03'),
('4522616717675333', 2, '2020-04-03'),
('4535569466151528', 3, '2018-02-04'),
('4566246626377112', 4, '2019-02-09'),
('4670902211105024', 5, '2018-02-01'),
('4609801005910630', 6, '2020-08-09'),
('4612239980177401', 7, '2018-02-01'),
('4999939288503462', 8, '2019-02-06'),
('4628987119585235', 9, '2019-05-02'),
('4889029092342005', 10, '2018-06-03');

INSERT INTO Registers (reg_date, sid, course_id, launch_date, cc_number) VALUES
('2020-01-03', 1, 1, '2021-03-10', '4566798466523378'),
('2020-01-03', 1, 2, '2021-03-25', '4566798466523378'),
('2020-01-03', 1, 1, '2021-03-10', '4522616717675333'),
('2020-01-03', 1, 1, '2021-03-10', '4535569466151528');

ALTER SEQUENCE Employees_eid_seq RESTART WITH 16;
ALTER SEQUENCE Rooms_rid_seq RESTART WITH 11;
ALTER SEQUENCE Courses_course_id_seq RESTART WITH 3;
-- Remember to add for the other tables that contain SERIAL