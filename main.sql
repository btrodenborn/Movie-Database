CREATE OR REPLACE FUNCTION timestamp_to_month(rental_timestamp TIMESTAMP)   
RETURNS VARCHAR(25)   
LANGUAGE plpgsql   
AS   
$$   

DECLARE month_of_rental VARCHAR(25);   
BEGIN   
SELECT date_part('month', rental_timestamp) INTO month_of_rental; 
RETURN month_of_rental;   
END;   
$$;   
 
DROP TABLE IF EXISTS detail_table;   
CREATE TABLE detail_table (   
film_id INT,    
title VARCHAR(255),  
category_id INT,   
category_name VARCHAR(25),     
rental_month VARCHAR(25),  
num_of_rentals INT  
 );

DROP TABLE IF EXISTS summary_table;   
CREATE TABLE summary_table (   
category_id int,  
category_name VARCHAR(25),   
rental_month VARCHAR(25),  
num_of_rentals INT  
);   

INSERT INTO detail_table(   
film_id,    
title,   
category_id,   
category_name,    
rental_month,  
num_of_rentals  
)   

SELECT   
f.film_id, f.title, fc.category_id, ca.name,   
timestamp_to_month(r.rental_date), COUNT(r.inventory_id)   

FROM rental AS r   
INNER JOIN inventory AS i ON i.inventory_id = r.inventory_id   
INNER JOIN film AS f ON f.film_id = i.film_id   
INNER JOIN film_category AS fc ON fc.film_id = f.film_id   
INNER JOIN category AS ca ON ca.category_id = fc.category_id  

GROUP BY timestamp_to_month(r.rental_date), fc.category_id, ca.name, f.film_id  
ORDER BY timestamp_to_month(r.rental_date), COUNT(r.inventory_id) DESC;  
 

CREATE OR REPLACE FUNCTION trigger_function()  
RETURNS TRIGGER  
LANGUAGE plpgsql  
AS $$  
BEGIN  
DELETE FROM summary_table;  
INSERT INTO summary_table  
SELECT category_id, category_name, rental_month, num_of_rentals  
FROM detail_table  

GROUP BY rental_month, category_id, category_name, num_of_rentals  
ORDER BY rental_month, num_of_rentals DESC;   

RETURN NEW;  
END;  
$$;  
  
CREATE TRIGGER trigger_start  
AFTER INSERT  
ON detail_table  
FOR EACH STATEMENT  
EXECUTE PROCEDURE trigger_function();  


CREATE OR REPLACE PROCEDURE refresh_table()  
LANGUAGE plpgsql  
AS $$  
BEGIN  
DELETE FROM detail_table;  
DELETE FROM summary_table; 
INSERT INTO detail_table  
SELECT   
	f.film_id, f.title, fc.category_id, ca.name,   
	timestamp_to_month(r.rental_date), COUNT(r.inventory_id)   

FROM rental AS r   
INNER JOIN inventory AS i ON i.inventory_id = r.inventory_id   
INNER JOIN film AS f ON f.film_id = i.film_id   
INNER JOIN film_category AS fc ON fc.film_id = f.film_id   
INNER JOIN category AS ca ON ca.category_id = fc.category_id  

GROUP BY timestamp_to_month(r.rental_date), fc.category_id, ca.name, f.film_id  
ORDER BY timestamp_to_month(r.rental_date), COUNT(r.inventory_id) DESC; 

INSERT INTO summary_table 
SELECT category_id, category_name, rental_month, num_of_rentals  
FROM detail_table  

GROUP BY rental_month, category_id, category_name, num_of_rentals  
ORDER BY rental_month, num_of_rentals DESC;  

RETURN;  
END;  
$$; 

CALL refresh_table();  

SELECT * FROM detail_table; 
