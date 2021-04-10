INSERT INTO Rooms (seating_capacity, location) VALUES
(100, 'LT15'),
(200, 'LT27'),
(420, 'COM1-0101'),
(2102, 'COM2-0102'),
(90, 'AS-27'),
(150, 'LT19'),
(15, 'COM1-0201'),
(15, 'COM2-0202'),
(100, 'LT16'),
(69, 'LT69');

-- Add to Customers, Credit_cards and Owns tables
CALL add_customer ('Amy Chen', 'Block 223 Serangoon Avenue 3 #03-42', '93742483', 'amychen@gmail.com', '4566798466523378', '516', '2028-05-03');
CALL add_customer ('Ben Davids', '1 University Road #01-02', '93753482', 'ben_davids@gmail.com', '4522616717675333', '222', '2024-04-02');
CALL add_customer ('Charlie Wong', 'Block 13 Woodlands Close #12-33', '89201483', 'charliew@gmail.com', '4535569466151528', '884', '2022-02-05');
CALL add_customer ('Dawn Lim', 'Block 5 Yishun Street 4 #07-224', '93115481', 'dawn_lim_oo@gmail.com', '4566246626377112', '644', '2026-04-06');
CALL add_customer ('Evan Ong', 'Block 114 Hougang Street 91 #03-10', '97810030', 'EvanONG@gmail.com', '4670902211105024', '102', '2029-08-07');
CALL add_customer ('Faizal Ali', 'Block 11 Tampines East Avenue 9 #08-41', '83722420', 'faizalali@gmail.com', '4609801005910630', '351', '2025-07-03');
CALL add_customer ('Govind Raju', 'Block 9 Serangoon North Avenue 1 #04-01', '89722433', 'govindr@gmail.com', '4612239980177401', '665', '2022-05-02');
CALL add_customer ('Halimah Wati', 'Block 832 Pasir Ris Street 22 #02-54', '90742284', 'halimahwati@gmail.com', '4999939288503462', '115', '2024-01-06');
CALL add_customer ('Ivy Lee', '1 Whampoa Street 1 #01-12', '91122485', 'ivysunshine@gmail.com', '4628987119585235', '412', '2028-02-01');
CALL add_customer ('Johnny Wong', 'Block 33 Yishun Ave 33 #07-123', '81922453', 'johnnywong@gmail.com', '4889029092342005', '143', '2026-03-05');

-- Add to Course_packages
CALL add_course_package('Package1', 10, 100, '2021-01-01', '2021-12-31');
CALL add_course_package('Package2', 20, 200, '2021-01-01', '2021-12-31');  
CALL add_course_package('Package3', 30, 300, '2021-01-01', '2021-12-31');
CALL add_course_package('Package4', 40, 400, '2021-01-01', '2021-12-31');
CALL add_course_package('Package5', 50, 500, '2021-01-01', '2021-12-31');  
CALL add_course_package('Package6', 60, 600, '2021-01-01', '2021-12-31');
CALL add_course_package('Package7', 70, 700, '2021-01-01', '2021-12-31');
CALL add_course_package('Package8', 80, 800, '2021-01-01', '2022-12-31');  
CALL add_course_package('Package9', 90, 900, '2021-01-01', '2021-12-31');
CALL add_course_package('Package10', 100, 1000, '2021-01-01', '2022-12-31');

-- Managers
CALL add_employee('Employee1', 'EAddress1', '90000001', 'EEmail1@u.nus.edu', 1000, NULL,  '2021-01-01', 'manager', ARRAY['Area1', 'Area2']::TEXT[]);
CALL add_employee('Employee2', 'EAddress2', '90000002', 'EEmail2@u.nus.edu', 2000, NULL,  '2021-01-01', 'manager', ARRAY['Area3']::TEXT[]);
CALL add_employee('Employee3', 'EAddress3', '90000003', 'EEmail3@u.nus.edu', 3000, NULL,  '2021-01-01', 'manager', ARRAY['Area4']::TEXT[]);
CALL add_employee('Employee4', 'EAddress4', '90000004', 'EEmail4@u.nus.edu', 4000, NULL,  '2021-01-01', 'manager', ARRAY['Area5']::TEXT[]);
CALL add_employee('Employee5', 'EAddress5', '90000005', 'EEmail5@u.nus.edu', 5000, NULL,  '2021-01-01', 'manager', ARRAY['Area4', 'Area5', 'Area6']::TEXT[]);
CALL add_employee('Employee6', 'EAddress6', '90000006', 'EEmail6@u.nus.edu', 6000, NULL,  '2021-01-01', 'manager', ARRAY['Area7']::TEXT[]);
CALL add_employee('Employee7', 'EAddress7', '90000007', 'EEmail7@u.nus.edu', 7000, NULL,  '2021-01-01', 'manager', ARRAY['Area8']::TEXT[]);
CALL add_employee('Employee8', 'EAddress8', '90000008', 'EEmail8@u.nus.edu', 8000, NULL,  '2021-01-01', 'manager', ARRAY['Area9']::TEXT[]);
CALL add_employee('Employee9', 'EAddress9', '90000009', 'EEmail9@u.nus.edu', 9000, NULL,  '2021-01-01', 'manager', ARRAY['Area8', 'Area9']::TEXT[]);
CALL add_employee('Employee10', 'EAddress10', '90000010', 'EEmail10@u.nus.edu', 10000, NULL,  '2021-01-01', 'manager', ARRAY['Area10']::TEXT[]);

-- Full Time Instructors
CALL add_employee('Employee11', 'EAddress11', '90000011', 'EEmail11@u.nus.edu', 1000, NULL,  '2021-01-01', 'instructor', ARRAY['Area1', 'Area2']::TEXT[]);
CALL add_employee('Employee12', 'EAddress12', '90000012', 'EEmail12@u.nus.edu', 2000, NULL,  '2021-01-01', 'instructor', ARRAY['Area1', 'Area2']::TEXT[]);
CALL add_employee('Employee13', 'EAddress13', '90000013', 'EEmail13@u.nus.edu', 3000, NULL,  '2021-01-01', 'instructor', ARRAY['Area3', 'Area4']::TEXT[]);
CALL add_employee('Employee14', 'EAddress14', '90000014', 'EEmail14@u.nus.edu', 4000, NULL,  '2021-01-01', 'instructor', ARRAY['Area2']::TEXT[]);
CALL add_employee('Employee15', 'EAddress15', '90000015', 'EEmail15@u.nus.edu', 5000, NULL,  '2021-01-01', 'instructor', ARRAY['Area3', 'Area4', 'Area5', 'Area6', 'Area7', 'Area8']::TEXT[]);

-- Part Time Instructors
CALL add_employee('Employee16', 'EAddress16', '90000016', 'EEmail16@u.nus.edu', NULL, 6,  '2021-01-01', 'instructor', ARRAY['Area1', 'Area2']::TEXT[]);
CALL add_employee('Employee17', 'EAddress17', '90000017', 'EEmail17@u.nus.edu', NULL, 7,  '2021-01-01', 'instructor', ARRAY['Area2', 'Area8']::TEXT[]);
CALL add_employee('Employee18', 'EAddress18', '90000018', 'EEmail18@u.nus.edu', NULL, 8,  '2021-01-01', 'instructor', ARRAY['Area9']::TEXT[]);
CALL add_employee('Employee19', 'EAddress19', '90000019', 'EEmail19@u.nus.edu', NULL, 9,  '2021-01-01', 'instructor', ARRAY['Area4']::TEXT[]);
CALL add_employee('Employee20', 'EAddress20', '90000020', 'EEmail20@u.nus.edu', NULL, 10,  '2021-01-01', 'instructor', ARRAY['Area1', 'Area2', 'Area3', 'Area4', 'Area5']::TEXT[]);
CALL add_employee('Employee21', 'EAddress21', '90000021', 'EEmail21@u.nus.edu', NULL, 10,  '2021-01-01', 'instructor', ARRAY['Area4']::TEXT[]);
CALL add_employee('Employee22', 'EAddress22', '90000022', 'EEmail22@u.nus.edu', NULL, 10,  '2021-01-01', 'instructor', ARRAY['Area5']::TEXT[]);
CALL add_employee('Employee23', 'EAddress23', '90000023', 'EEmail23@u.nus.edu', NULL, 10,  '2021-01-01', 'instructor', ARRAY['Area6']::TEXT[]);
CALL add_employee('Employee24', 'EAddress24', '90000024', 'EEmail24@u.nus.edu', NULL, 10,  '2021-01-01', 'instructor', ARRAY['Area7']::TEXT[]);
CALL add_employee('Employee25', 'EAddress25', '90000025', 'EEmail25@u.nus.edu', NULL, 10,  '2021-01-01', 'instructor', ARRAY['Area8']::TEXT[]);

-- Administrators
CALL add_employee('Employee26', 'EAddress26', '90000026', 'EEmail26@u.nus.edu', 1000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee27', 'EAddress27', '90000027', 'EEmail27@u.nus.edu', 2000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee28', 'EAddress28', '90000028', 'EEmail28@u.nus.edu', 3000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee29', 'EAddress29', '90000029', 'EEmail29@u.nus.edu', 4000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee30', 'EAddress30', '90000030', 'EEmail30@u.nus.edu', 5000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee31', 'EAddress31', '90000031', 'EEmail31@u.nus.edu', 6000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee32', 'EAddress32', '90000032', 'EEmail32@u.nus.edu', 7000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee33', 'EAddress33', '90000033', 'EEmail33@u.nus.edu', 8000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee34', 'EAddress34', '90000034', 'EEmail34@u.nus.edu', 9000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);
CALL add_employee('Employee35', 'EAddress35', '90000035', 'EEmail35@u.nus.edu', 10000, NULL,  '2021-01-01', 'administrator', ARRAY[]::TEXT[]);


-- Add to Courses
CALL add_course('Title1', 'Description1', 'Area1', 1);
CALL add_course('Title2', 'Description2', 'Area1', 2);
CALL add_course('Title3', 'Description3', 'Area2', 3);
CALL add_course('Title4', 'Description4', 'Area2', 4);
CALL add_course('Title5', 'Description5', 'Area3', 1);
CALL add_course('Title6', 'Description6', 'Area4', 2);
CALL add_course('Title7', 'Description7', 'Area4', 3);
CALL add_course('Title8', 'Description8', 'Area4', 4);
CALL add_course('Title9', 'Description9', 'Area5', 1);
CALL add_course('Title10', 'Description10', 'Area6', 2);

-- Add to Course_offerings and Sessions
CALL add_course_offering(1, 100, '2021-01-01', '2021-04-10', 50, 26, ARRAY['2021-06-01', '2021-06-01', '2021-06-01', '2021-06-02', '2021-06-02']::date[], '{9, 15, 16, 9, 15}', '{1, 1, 1, 1, 1}');
CALL add_course_offering(1, 200, '2021-02-01', '2021-05-11', 40, 27, ARRAY['2021-07-01', '2021-07-01', '2021-07-01', '2021-07-15']::date[], '{10, 14, 15, 9}', '{1, 1, 1, 1}');
CALL add_course_offering(1, 300, '2021-03-01', '2021-06-10', 30, 28, ARRAY['2021-08-01', '2021-08-02', '2021-08-03']::date[], '{15, 16, 17}', '{1, 1, 1}');
CALL add_course_offering(2, 200, '2021-01-01', '2021-04-10', 100, 29, ARRAY['2021-06-01', '2021-06-01', '2021-06-01', '2021-06-15', '2021-07-15']::date[], '{9, 10, 14, 9, 10}', '{2, 3, 2, 1, 2}');
CALL add_course_offering(2, 300, '2021-02-01', '2021-05-11', 60, 30, ARRAY['2021-07-01', '2021-07-01', '2021-07-02']::date[], '{15, 16, 9}', '{2, 3, 1}');
CALL add_course_offering(3, 100, '2021-01-01', '2021-04-10', 70, 31, ARRAY['2021-06-01', '2021-06-01']::date[], '{9, 15}', '{4, 3}');
CALL add_course_offering(4, 100, '2021-01-01', '2021-04-10', 80, 32, ARRAY['2021-06-01', '2021-06-02', '2021-06-03', '2021-06-04']::date[], '{14, 14, 14, 14}', '{4, 2, 1, 1}');
CALL add_course_offering(5, 200, '2021-02-01', '2021-05-11', 40, 33, ARRAY['2021-07-01']::date[], '{15}', '{4}');
CALL add_course_offering(5, 300, '2021-03-01', '2021-06-10', 80, 34, ARRAY['2021-08-01', '2021-08-02', '2021-08-03', '2021-09-01', '2021-09-30']::date[], '{15, 16, 17, 9, 9}', '{2, 2, 2, 1, 1}');
CALL add_course_offering(6, 100, '2021-01-01', '2021-04-10', 170, 35, ARRAY['2021-06-01', '2021-06-01', '2021-06-02', '2021-06-02', '2021-06-03', '2021-06-03']::date[], '{9, 15, 9, 15, 9, 15}', '{5, 5, 2, 3, 1, 2}');

-- Add to Buys
CALL buy_course_package (1, 1);
CALL buy_course_package (2, 2);
CALL buy_course_package (3, 3);
CALL buy_course_package (4, 4);
CALL buy_course_package (5, 5);
CALL buy_course_package (6, 5);
CALL buy_course_package (7, 5);
CALL buy_course_package (8, 4);
CALL buy_course_package (9, 3);
CALL buy_course_package (10, 6);

-- Add to Registers and Redeems
CALL register_session(1, 1, '2021-01-01', 1, 'credit_card');
CALL register_session(1, 2, '2021-02-01', 1, 'credit_card');
-- CALL register_session(1, 3, '2021-03-01', 1, 'credit_card');
-- CALL register_session(1, 5, '2021-01-01', 2, 'credit_card');
-- CALL register_session(1, 3, '2021-02-01', 2, 'credit_card');
CALL register_session(1, 1, '2021-01-01', 3, 'credit_card');
CALL register_session(1, 4, '2021-01-01', 4, 'credit_card');
-- CALL register_session(1, 1, '2021-02-01', 5, 'credit_card');
-- CALL register_session(1, 1, '2021-03-01', 5, 'credit_card');
CALL register_session(2, 3, '2021-01-01', 1, 'credit_card');
-- CALL register_session(2, 3, '2021-03-01', 1, 'credit_card');
CALL register_session(2, 4, '2021-01-01', 2, 'credit_card');
CALL register_session(2, 2, '2021-02-01', 2, 'credit_card');
CALL register_session(2, 4, '2021-01-01', 4, 'credit_card');
-- CALL register_session(2, 1, '2021-02-01', 5, 'credit_card');
-- CALL register_session(2, 2, '2021-03-01', 5, 'credit_card');
-- CALL register_session(2, 4, '2021-01-01', 6, 'credit_card');
-- CALL register_session(3, 5, '2021-01-01', 2, 'credit_card');
-- CALL register_session(3, 3, '2021-02-01', 2, 'credit_card');
CALL register_session(3, 2, '2021-01-01', 3, 'credit_card');
CALL register_session(3, 4, '2021-01-01', 4, 'credit_card');
-- CALL register_session(5, 2, '2021-03-01', 1, 'credit_card');
-- CALL register_session(6, 3, '2021-03-01', 1, 'credit_card');
-- CALL register_session(8, 3, '2021-03-01', 1, 'credit_card');
CALL register_session(8, 2, '2021-01-01', 2, 'credit_card');
CALL register_session(10, 1, '2021-01-01', 2, 'credit_card');

CALL register_session(1, 6, '2021-01-01', 6, 'package');
CALL register_session(2, 1, '2021-02-01', 1, 'package');
CALL register_session(2, 1, '2021-01-01', 3, 'package');
CALL register_session(3, 2, '2021-01-01', 1, 'package');
-- CALL register_session(3, 4, '2021-02-01', 1, 'package');
-- CALL register_session(3, 3, '2021-03-01', 1, 'package');
-- CALL register_session(5, 1, '2021-02-01', 5, 'package');
-- CALL register_session(5, 4, '2021-01-01', 6, 'package');
CALL register_session(5, 2, '2021-01-01', 4, 'package');
-- CALL register_session(5, 1, '2021-03-01', 5, 'package');
-- CALL register_session(6, 1, '2021-02-01', 5, 'package');
CALL register_session(6, 4, '2021-01-01', 4, 'package');
-- CALL register_session(8, 1, '2021-02-01', 5, 'package');
-- CALL register_session(8, 2, '2021-03-01', 5, 'package');
-- CALL register_session(10, 1, '2021-03-01', 5, 'package');

-- Add to Cancels
-- CALL cancel_registration(1, 1, '2021-01-01');
-- CALL cancel_registration(1, 1, '2021-02-01');
-- CALL cancel_registration(1, 6, '2021-01-01');
-- CALL cancel_registration(2, 2, '2021-02-01');
-- CALL cancel_registration(2, 1, '2021-02-01');
-- CALL cancel_registration(2, 5, '2021-02-01');
-- CALL cancel_registration(3, 1, '2021-03-01');
-- CALL cancel_registration(5, 4, '2021-01-01');
-- CALL cancel_registration(10, 2,  '2021-01-01');
-- CALL cancel_registration(10, 5,  '2021-03-01');
