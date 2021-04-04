-- CS2102 Project Team 41 proc.sql

-- 3. TODO: INCOMPLETE
CREATE OR REPLACE PROCEDURE add_customer (cust_name TEXT, address TEXT, phone TEXT, email TEXT, cc_number char(20), cvv INT, expiry_date DATE)
AS $$
BEGIN
	INSERT INTO Customers (cust_name, address, phone, email)
	VALUES (cust_name, address, phone, email);
END;
$$ LANGUAGE plpgsql;
