#create a database 
CREATE DATABASE IF NOT EXISTS ola_analytics;
USE ola_analytics;

##create a table 
CREATE TABLE ola_bookings_raw (
    Date VARCHAR(20),
    Time TIME,
    Booking_ID VARCHAR(30) PRIMARY KEY,
    Booking_Status VARCHAR(30),
    Customer_ID VARCHAR(20),
    Vehicle_Type VARCHAR(20),
    Pickup_Location VARCHAR(50),
    Drop_Location VARCHAR(50),
    V_TAT INT NULL,
    C_TAT INT NULL,
    Canceled_Rides_by_Customer VARCHAR(100) NULL,
    Canceled_Rides_by_Driver VARCHAR(100) NULL,
    Incomplete_Rides VARCHAR(10) NULL,
    Incomplete_Rides_Reason VARCHAR(50) NULL,
    Booking_Value INT,
    Payment_Method VARCHAR(20) NULL,
    Ride_Distance INT,
    Driver_Ratings DECIMAL(3,1) NULL,
    Customer_Rating DECIMAL(3,1) NULL,
    `Vehicle Images` VARCHAR(10) NULL,
    Column1 VARCHAR(100) NULL
);

#load data in the table from files due to we have a large 1.2 lakh rows data so its take so time to laod with the help of manual import wizard laod
-- Step 1: Allow local file loading 
SET GLOBAL local_infile = 1;

-- Step 2: Load the CSV directly into ola_bookings_raw
LOAD DATA LOCAL INFILE 'D:/olaBookings_Raw_data.csv'
INTO TABLE ola_analytics.ola_bookings_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    Date, Time, Booking_ID, Booking_Status, Customer_ID,
    Vehicle_Type, Pickup_Location, Drop_Location,
    @V_TAT, @C_TAT,
    @Canceled_Rides_by_Customer, @Canceled_Rides_by_Driver,
    @Incomplete_Rides, @Incomplete_Rides_Reason,
    Booking_Value, @Payment_Method, Ride_Distance,
    @Driver_Ratings, @Customer_Rating,
    @Vehicle_Images, @Column1
)
SET
    V_TAT = NULLIF(@V_TAT, ''),
    C_TAT = NULLIF(@C_TAT, ''),
    Canceled_Rides_by_Customer = NULLIF(@Canceled_Rides_by_Customer, ''),
    Canceled_Rides_by_Driver = NULLIF(@Canceled_Rides_by_Driver, ''),
    Incomplete_Rides = NULLIF(@Incomplete_Rides, ''),
    Incomplete_Rides_Reason = NULLIF(@Incomplete_Rides_Reason, ''),
    Payment_Method = NULLIF(@Payment_Method, ''),
    Driver_Ratings = NULLIF(@Driver_Ratings, ''),
    Customer_Rating = NULLIF(@Customer_Rating, ''),
    `Vehicle Images` = NULLIF(@Vehicle_Images, ''),
    Column1 = NULLIF(@Column1, '');
    
    
    
    
#Business Questions and their answers 
#Q1. How many total bookings were recorded in July 2024, and what is the count and total Booking_Value for each Booking_Status (Success, Canceled by Driver, Canceled by Customer, Driver Not Found)?
SELECT
    Booking_Status,
    COUNT(Booking_ID) AS total_bookings,
    SUM(Booking_Value) AS total_booking_value
FROM ola_analytics.ola_bookings_raw
GROUP BY Booking_Status
ORDER BY total_bookings DESC;

#Q2. What is the total realized revenue (Booking_Status = 'Success') compared to the total value of unsuccessful bookings?
SELECT
    CASE
        WHEN Booking_Status = 'Success' THEN 'Realized Revenue (Success)'
        ELSE 'Unsuccessful Booking Value'
    END AS revenue_type,
    COUNT(Booking_ID) AS total_bookings,
    SUM(Booking_Value) AS total_value
FROM ola_analytics.ola_bookings_raw
GROUP BY revenue_type;

#Q3. What are the minimum, average, and maximum Booking_Value for successful rides versus canceled rides?
SELECT
    CASE
        WHEN Booking_Status = 'Success' THEN 'Success'
        ELSE 'Not Success'
    END AS ride_group,
    MIN(Booking_Value) AS min_booking_value,
    ROUND(AVG(Booking_Value), 2) AS avg_booking_value,
    MAX(Booking_Value) AS max_booking_value
FROM ola_analytics.ola_bookings_raw
GROUP BY ride_group;

#Q4. Which 10 dates in July 2024 recorded the highest number of bookings and the highest realized revenue?
SELECT
    STR_TO_DATE(Date, '%d-%m-%Y') AS booking_date,
    COUNT(Booking_ID) AS total_bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN Booking_Value ELSE 0 END) AS realized_revenue
FROM ola_analytics.ola_bookings_raw
GROUP BY booking_date
ORDER BY realized_revenue DESC
LIMIT 10;

#Q5. How do Success ride counts, total Booking_Value, and average Ride_Distance compare across all 7 Vehicle_Type categories?
SELECT
    Vehicle_Type,
    COUNT(Booking_ID) AS successful_rides,
    SUM(Booking_Value) AS realized_revenue,
    ROUND(AVG(Ride_Distance), 2) AS avg_ride_distance_km
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY realized_revenue DESC;

#Q6. Which Vehicle_Type has the highest count of Canceled by Driver and Driver Not Found bookings?
SELECT
    Vehicle_Type,
    SUM(CASE WHEN Booking_Status = 'Canceled by Driver' THEN 1 ELSE 0 END) AS driver_canceled_count,
    SUM(CASE WHEN Booking_Status = 'Driver Not Found' THEN 1 ELSE 0 END) AS driver_not_found_count
FROM ola_analytics.ola_bookings_raw
GROUP BY Vehicle_Type
ORDER BY driver_canceled_count DESC;

#Q7. How many completed rides were paid via Cash, UPI, Credit Card, and Debit Card, and what is the total revenue for each payment method?
SELECT
    Payment_Method,
    COUNT(Booking_ID) AS completed_rides,
    SUM(Booking_Value) AS realized_revenue
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Payment_Method
ORDER BY realized_revenue DESC;

#Q8. For each Vehicle_Type, which Payment_Method is used the most for successful rides?
SELECT
    Vehicle_Type,
    Payment_Method,
    COUNT(Booking_ID) AS completed_rides,
    SUM(Booking_Value) AS realized_revenue
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type, Payment_Method
ORDER BY Vehicle_Type, completed_rides DESC;

#Q9. How many bookings fall under each Canceled_Rides_by_Driver reason, and what is the total Booking_Value tied to each reason?
SELECT
    Canceled_Rides_by_Driver,
    COUNT(Booking_ID) AS cancel_count,
    SUM(Booking_Value) AS total_booking_value
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Canceled by Driver'
GROUP BY Canceled_Rides_by_Driver
ORDER BY cancel_count DESC;

#Q10. How many bookings fall under each Canceled_Rides_by_Customer reason, and which reason happens the most?
SELECT
    Canceled_Rides_by_Customer,
    COUNT(Booking_ID) AS cancel_count,
    SUM(Booking_Value) AS total_booking_value
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Canceled by Customer'
GROUP BY Canceled_Rides_by_Customer
ORDER BY cancel_count DESC;

#Q11. Among Success bookings, how many rides have Incomplete_Rides = 'Yes' versus 'No'?
SELECT
    Incomplete_Rides,
    COUNT(Booking_ID) AS ride_count,
    SUM(Booking_Value) AS total_booking_value
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Incomplete_Rides;

#Q12. For incomplete rides (Incomplete_Rides = 'Yes'), how many occur under each Incomplete_Rides_Reason (Customer Demand, Vehicle Breakdown, Other Issue), and which Vehicle_Type has the most incomplete rides?
SELECT
    Incomplete_Rides_Reason,
    COUNT(Booking_ID) AS incomplete_count,
    SUM(Booking_Value) AS total_booking_value
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success' AND Incomplete_Rides = 'Yes'
GROUP BY Incomplete_Rides_Reason
ORDER BY incomplete_count DESC;

SELECT
    Vehicle_Type,
    COUNT(Booking_ID) AS incomplete_rides_count
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success' AND Incomplete_Rides = 'Yes'
GROUP BY Vehicle_Type
ORDER BY incomplete_rides_count DESC;

#Q13. Which are the top 10 Pickup_Location areas by total bookings, successful rides, and Driver Not Found count?
SELECT
    Pickup_Location,
    COUNT(Booking_ID) AS total_bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) AS successful_rides,
    SUM(CASE WHEN Booking_Status = 'Driver Not Found' THEN 1 ELSE 0 END) AS driver_not_found_count
FROM ola_analytics.ola_bookings_raw
GROUP BY Pickup_Location
ORDER BY total_bookings DESC
LIMIT 10;

#Q14. Which are the top 10 Drop_Location areas for completed rides?
SELECT
    Drop_Location,
    COUNT(Booking_ID) AS completed_rides,
    SUM(Booking_Value) AS realized_revenue
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Drop_Location
ORDER BY completed_rides DESC
LIMIT 10;

#Q15. Which specific Pickup_Location to Drop_Location routes have the highest number of completed rides and highest realized revenue?
SELECT
    CONCAT(Pickup_Location, ' to ', Drop_Location) AS route,
    COUNT(Booking_ID) AS completed_rides,
    SUM(Booking_Value) AS realized_revenue
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY route
ORDER BY completed_rides DESC
LIMIT 10;

#Q16. How many bookings have Pickup_Location = Drop_Location, and how many of them were Success vs. canceled?
SELECT
    Booking_Status,
    COUNT(Booking_ID) AS booking_count
FROM ola_analytics.ola_bookings_raw
WHERE Pickup_Location = Drop_Location
GROUP BY Booking_Status
ORDER BY booking_count DESC;

#Q17. How do total bookings and successful rides change across each hour of the day (0 to 23)?
SELECT
    HOUR(Time) AS booking_hour,
    COUNT(Booking_ID) AS total_bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) AS successful_rides
FROM ola_analytics.ola_bookings_raw
GROUP BY booking_hour
ORDER BY booking_hour;

#Q18. How do average Ride_Distance and average Booking_Value compare across short (<= 10 km), medium (11-25 km), and long (> 25 km) completed trips?
SELECT
    CASE
        WHEN Ride_Distance <= 10 THEN 'Short (<= 10 km)'
        WHEN Ride_Distance BETWEEN 11 AND 25 THEN 'Medium (11-25 km)'
        ELSE 'Long (> 25 km)'
    END AS distance_category,
    COUNT(Booking_ID) AS completed_rides,
    ROUND(AVG(Ride_Distance), 2) AS avg_distance_km,
    ROUND(AVG(Booking_Value), 2) AS avg_booking_value
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY distance_category
ORDER BY avg_distance_km;

#Q19. What is the average V_TAT and C_TAT for successful rides across each Vehicle_Type?
SELECT
    Vehicle_Type,
    ROUND(AVG(V_TAT), 2) AS avg_v_tat,
    ROUND(AVG(C_TAT), 2) AS avg_c_tat
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY Vehicle_Type;

#Q20. What are the average Driver_Ratings and Customer_Rating for each Vehicle_Type on completed rides?
SELECT
    Vehicle_Type,
    ROUND(AVG(Driver_Ratings), 2) AS avg_driver_rating,
    ROUND(AVG(Customer_Rating), 2) AS avg_customer_rating
FROM ola_analytics.ola_bookings_raw
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY Vehicle_Type;