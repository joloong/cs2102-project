-- CS2102 Project Team 41 data.sql

DELETE FROM Employees;
DELETE FROM Part_time_Emp;
DELETE FROM Full_time_Emp;
DELETE FROM Instructors;
DELETE FROM Part_time_instructors;
DELETE FROM Full_time_instructors;
DELETE FROM Administrators;
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

INSERT INTO Credit_cards (cc_number, cvv, expiry_date) VALUES
(1234567891011121, 123, '2013-06-01');
