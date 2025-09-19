-- Check the first 100 records to understand the data
SELECT * FROM portfolioproject.uber
LIMIT 100;

-- Get basic statistics about the table
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT Booking_ID) AS unique_bookings,
    COUNT(DISTINCT LEFT(Customer_ID, 50)) AS unique_customers
FROM `portfolioproject`.`uber`;

-- Check for missing values in important columns
SELECT 
    SUM(CASE WHEN Date IS NULL OR Date = '' THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN Time IS NULL OR Time = '' THEN 1 ELSE 0 END) AS missing_time,
    SUM(CASE WHEN Booking_ID IS NULL OR Booking_ID = '' THEN 1 ELSE 0 END) AS missing_booking_id,
    SUM(CASE WHEN Booking_Status IS NULL OR Booking_Status = '' THEN 1 ELSE 0 END) AS missing_booking_status,
    SUM(CASE WHEN Booking_Value IS NULL THEN 1 ELSE 0 END) AS missing_booking_value,
    SUM(CASE WHEN Ride_Distance IS NULL THEN 1 ELSE 0 END) AS missing_ride_distance
FROM `portfolioproject`.`uber`;

-- Create a new table for the cleaned data
CREATE TABLE `portfolioproject`.`uber_clean`LIKE `portfolioproject`.`uber`;

-- Insert all records into the new table
INSERT INTO `portfolioproject`.`uber_clean`
SELECT * FROM `portfolioproject`.`uber`;

-- Add a proper datetime column
ALTER TABLE `portfolioproject`.`uber_clean`
ADD COLUMN Booking_DateTime DATETIME AFTER Time;

-- Update the new datetime column
UPDATE `portfolioproject`.`uber_clean`
SET Booking_DateTime = STR_TO_DATE(CONCAT(Date, ' ', Time), '%Y/%m/%d %H:%i:%s')
WHERE Date IS NOT NULL AND Time IS NOT NULL;

-- Handle any invalid dates (if the update fails for some records)
SELECT * 
FROM `portfolioproject`.`uber_clean`
WHERE Booking_DateTime IS NULL AND Date IS NOT NULL AND Time IS NOT NULL;

-- Add columns for day of week, hour of day, month, and year for easier time-based analysis
ALTER TABLE `portfolioproject`.`uber_clean`
ADD COLUMN Day_Of_Week VARCHAR(10) AFTER Booking_DateTime,
ADD COLUMN Hour_Of_Day INT AFTER Day_Of_Week,
ADD COLUMN `Month` INT AFTER Hour_Of_Day,
ADD COLUMN `Year` INT AFTER Month;

UPDATE `portfolioproject`.`uber_clean`
SET 
    Day_Of_Week = DAYNAME(Booking_DateTime),
    Hour_Of_Day = HOUR(Booking_DateTime),
    `Month` = MONTH(Booking_DateTime),
    `Year` = YEAR(Booking_DateTime)
WHERE Booking_DateTime IS NOT NULL;

-- Standardize Booking_Status values (convert to proper case and fix any misspellings)
SELECT DISTINCT Booking_Status 
FROM `portfolioproject`.`uber_clean`;

UPDATE `portfolioproject`.`uber_clean`
SET Booking_Status = CASE 
    WHEN LOWER(Booking_Status) = 'completed' THEN 'Completed'
    WHEN LOWER(Booking_Status) = 'cancelled by driver' THEN 'Cancelled by Driver'
    WHEN LOWER(Booking_Status) = 'incomplete' THEN 'Incomplete'
    WHEN LOWER(Booking_Status) = 'cancelled by customer' THEN 'Cancelled by Costumer'
    WHEN LOWER(Booking_Status) = 'No driver found ' THEN 'No Driver Found'
    ELSE Booking_Status
END;

-- Standardize Vehicle_Type values
SELECT DISTINCT Vehicle_Type 
FROM `portfolioproject`.`uber_clean`;

UPDATE `portfolioproject`.`uber_clean`
SET Vehicle_Type = TRIM(Vehicle_Type);

UPDATE `portfolioproject`.`uber_clean`
SET Vehicle_Type = CASE 
    WHEN LOWER(Vehicle_Type) = 'eBike' THEN 'Ebike'
    WHEN LOWER(Vehicle_Type) = 'Go sedan' THEN 'Go Sedan'
    WHEN LOWER(Vehicle_Type) = 'Auto' THEN 'Auto'
    WHEN LOWER(Vehicle_Type) = 'Premier Sedan' THEN 'Premier Sedan'
    WHEN LOWER(Vehicle_Type) = 'Bike' THEN 'Bike'
    WHEN LOWER(Vehicle_Type) = 'Go Mini' THEN 'Go Mini'
    WHEN LOWER(Vehicle_Type) = 'Uber xl' THEN 'Uber XL'
    ELSE Vehicle_Type
END;

-- Standardize Payment_Method
SELECT DISTINCT Payment_Method 
FROM `portfolioproject`.`uber_clean`;

UPDATE `portfolioproject`.`uber_clean`
SET Payment_Method = CASE 
    WHEN LOWER(Payment_Method) LIKE '%credit%' OR LOWER(Payment_Method) LIKE '%credit card%' THEN 'Credit Card'
    WHEN LOWER(Payment_Method) LIKE '%debit%' OR LOWER(Payment_Method) LIKE '%debit card%' THEN 'Debit Card'
    WHEN LOWER(Payment_Method) LIKE '%cash%' THEN 'Cash'
    WHEN LOWER(Payment_Method) LIKE '%wallet%' THEN 'Digital Wallet'
    WHEN Payment_Method IS NULL THEN 'Unknown'
    WHEN LOWER(Payment_Method) LIKE 'UPI' THEN 'UPI'
    ELSE Payment_Method
END;

-- Identify null values in important numeric columns
SELECT 
    SUM(CASE WHEN Avg_VTAT IS NULL THEN 1 ELSE 0 END) AS null_avg_vtat,
    SUM(CASE WHEN Avg_CTAT IS NULL THEN 1 ELSE 0 END) AS null_avg_ctat,
    SUM(CASE WHEN Booking_Value IS NULL THEN 1 ELSE 0 END) AS null_booking_value,
    SUM(CASE WHEN Ride_Distance IS NULL THEN 1 ELSE 0 END) AS null_ride_distance,
    SUM(CASE WHEN Driver_Ratings IS NULL THEN 1 ELSE 0 END) AS null_driver_ratings,
    SUM(CASE WHEN Customer_Rating IS NULL THEN 1 ELSE 0 END) AS null_customer_rating,
    SUM(CASE WHEN Cancelled_Rides_by_Customer IS NULL THEN 1 ELSE 0 END) AS null_Cancelled_Rides_by_Customer,
	SUM(CASE WHEN Cancelled_Rides_by_Driver IS NULL THEN 1 ELSE 0 END) AS null_Cancelled_Rides_by_Driver,
    SUM(CASE WHEN Incomplete_Rides IS NULL THEN 1 ELSE 0 END) AS null_Incomplete_Rides
FROM `portfolioproject`.`uber_clean`;

-- Calculate average values for potential imputation
SELECT 
    AVG(Avg_VTAT) AS avg_vtat,
    AVG(Avg_CTAT) AS avg_ctat,
    AVG(Booking_Value) AS avg_booking_value,
    AVG(Ride_Distance) AS avg_ride_distance,
    AVG(Driver_Ratings) AS avg_driver_ratings,
    AVG(Customer_Rating) AS avg_customer_rating,
    AVG(Cancelled_Rides_by_Customer) AS avg_Cancelled_Rides_by_Customer,
    AVG(Cancelled_Rides_by_Driver) AS avg_Cancelled_Rides_by_Driver,
    AVG(Incomplete_Rides) AS avg_Incomplete_Rides
FROM `portfolioproject`.`uber_clean`;

-- Fill missing Booking_Value with 0 for canceled rides
UPDATE `portfolioproject`.`uber_clean`
SET Booking_Value = 0
WHERE Booking_Value IS NULL AND (
    Booking_Status = 'Cancelled' OR 
    Cancelled_Rides_by_Customer = 1 OR 
    Cancelled_Rides_by_Driver = 1
);
SELECT COUNT(*) FROM `portfolioproject`.`uber_clean` WHERE Booking_Value IS NULL;

-- Fill in missing ratings for completed rides with the average
UPDATE `portfolioproject`.`uber_clean`
SET Driver_Ratings = (
    SELECT avg_rating FROM (
        SELECT AVG(Driver_Ratings) AS avg_rating
        FROM `portfolioproject`.`uber_clean`
        WHERE Driver_Ratings IS NOT NULL
    ) AS derived_table
)
WHERE Driver_Ratings IS NULL AND Booking_Status = 'Completed';
SELECT COUNT(*) FROM `portfolioproject`.`uber_clean` WHERE Driver_Ratings IS NULL;

UPDATE `portfolioproject`.`uber_clean`
SET Customer_Rating = (
    SELECT avg_rating FROM (
        SELECT AVG(Customer_Rating) AS avg_rating
        FROM `portfolioproject`.`uber_clean`
        WHERE Customer_Rating IS NOT NULL
    ) AS derived_table
)
WHERE Customer_Rating IS NULL AND Booking_Status = 'Completed';
SELECT COUNT(*) FROM `portfolioproject`.`uber_clean` WHERE Customer_Rating IS NULL;

-- Add a column for price per kilometer
ALTER TABLE `portfolioproject`.`uber_clean`
ADD COLUMN Price_Per_Km DECIMAL(10, 2) AFTER Booking_Value;

UPDATE `portfolioproject`.`uber_clean`
SET Price_Per_Km = 
    CASE 
        -- When distance is very small (less than 0.1 km), use NULL or a cap value
        WHEN Ride_Distance < 0.1 THEN NULL
        -- When the calculation results in an extreme value, cap it
        WHEN (Booking_Value / Ride_Distance) > 1000 THEN 1000
        -- Normal calculation
        WHEN Ride_Distance > 0 THEN Booking_Value / Ride_Distance 
        ELSE NULL 
    END
WHERE Booking_Status = 'Completed';

UPDATE `portfolioproject`.`uber_clean`
SET Price_Per_Km = 
    CASE 
        WHEN Ride_Distance > 0 THEN ROUND(Booking_Value / Ride_Distance, 2)
        ELSE NULL 
    END
WHERE Booking_Status = 'Completed';

-- Add a flag for peak hours (assuming 7-9 AM and 5-7 PM are peak hours)
ALTER TABLE `portfolioproject`.`uber_clean`
ADD COLUMN Is_Peak_Hour BOOLEAN AFTER Hour_Of_Day;

UPDATE `portfolioproject`.`uber_clean`
SET Is_Peak_Hour = 
    CASE 
        WHEN (Hour_Of_Day BETWEEN 7 AND 9) OR (Hour_Of_Day BETWEEN 17 AND 19) THEN 1
        ELSE 0
    END
WHERE Hour_Of_Day IS NOT NULL;

-- Add a column for weekend flag
ALTER TABLE `portfolioproject`.`uber_clean`
ADD COLUMN Is_Weekend BOOLEAN AFTER Day_Of_Week;

UPDATE `portfolioproject`.`uber_clean`
SET Is_Weekend = 
    CASE 
        WHEN Day_Of_Week IN ('Saturday', 'Sunday') THEN 1
        ELSE 0
    END
WHERE Day_Of_Week IS NOT NULL;

-- Add indexes to improve query performance
CREATE INDEX idx_booking_datetime ON `portfolioproject`.`uber_clean`(Booking_DateTime);
CREATE INDEX idx_booking_status ON `portfolioproject`.`uber_clean` (Booking_Status(50));
CREATE INDEX idx_customer_id ON `portfolioproject`.`uber_clean` (Customer_ID(50));
CREATE INDEX idx_vehicle_type ON `portfolioproject`.`uber_clean`  (Vehicle_Type(50));

-- View for completed rides summary
CREATE OR REPLACE VIEW `portfolioproject`.vw_completed_rides_summary AS
SELECT 
    Vehicle_Type,
    COUNT(*) AS total_rides,
    AVG(Booking_Value) AS avg_booking_value,
    AVG(Ride_Distance) AS avg_distance,
    AVG(Driver_Ratings) AS avg_driver_rating,
    AVG(Customer_Rating) AS avg_customer_rating,
    AVG(Price_Per_Km) AS avg_price_per_km
FROM `portfolioproject`.`uber_clean`
WHERE Booking_Status = 'Completed'
GROUP BY Vehicle_Type;

-- View for cancellation analysis
CREATE OR REPLACE VIEW `portfolioproject`.vw_cancellation_analysis AS
SELECT 
    Reason_for_cancelling_by_Customer,
    COUNT(*) AS cancellation_count,
    AVG(Avg_VTAT) AS avg_vehicle_arrival_time,
    AVG(Avg_CTAT) AS avg_customer_acceptance_time
FROM `portfolioproject`.`uber_clean`
WHERE Cancelled_Rides_by_Customer = 1 AND Reason_for_cancelling_by_Customer IS NOT NULL
GROUP BY Reason_for_cancelling_by_Customer
ORDER BY cancellation_count DESC;

-- View for hourly booking patterns
CREATE OR REPLACE VIEW `portfolioproject`.vw_hourly_booking_patterns AS
SELECT 
    Hour_Of_Day,
    Is_Weekend,
    Is_Peak_Hour,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) AS completed_bookings,
    SUM(CASE WHEN Cancelled_Rides_by_Customer = 1 THEN 1 ELSE 0 END) AS customer_cancellations,
    SUM(CASE WHEN Cancelled_Rides_by_Driver = 1 THEN 1 ELSE 0 END) AS driver_cancellations,
    AVG(Booking_Value) AS avg_booking_value,
    AVG(Ride_Distance) AS avg_ride_distance
FROM `portfolioproject`.`uber_clean`
GROUP BY Hour_Of_Day, Is_Weekend, Is_Peak_Hour
ORDER BY Hour_Of_Day;

-- View for payment method analysis
CREATE OR REPLACE VIEW `portfolioproject`.vw_payment_method_analysis AS
SELECT 
    Payment_Method,
    COUNT(*) AS total_rides,
    AVG(Booking_Value) AS avg_booking_value,
    SUM(Booking_Value) AS total_revenue
FROM `portfolioproject`.`uber_clean`
WHERE Booking_Status = 'Completed'
GROUP BY Payment_Method
ORDER BY total_revenue DESC;


-- Check the quality of the cleaned data
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN Booking_DateTime IS NULL THEN 1 ELSE 0 END) AS missing_datetime,
    SUM(CASE WHEN Booking_Status IS NULL THEN 1 ELSE 0 END) AS missing_status,
    SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) AS completed_rides,
    SUM(CASE WHEN Booking_Status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_rides,
    SUM(CASE WHEN Booking_Status = 'Incomplete' THEN 1 ELSE 0 END) AS incomplete_rides,
    AVG(Booking_Value) AS avg_booking_value,
    MAX(Booking_Value) AS max_booking_value,
    MIN(Booking_Value) AS min_booking_value,
    AVG(Ride_Distance) AS avg_ride_distance
FROM `portfolioproject`.`uber_clean`;

-- Create a comprehensive summary table for analysts
CREATE OR REPLACE VIEW `portfolioproject`.vw_ride_bookings_summary AS
SELECT
    CONCAT(YEAR(Booking_DateTime), '-', LPAD(MONTH(Booking_DateTime), 2, '0')) AS `year_month`,
    Vehicle_Type,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) AS completed_rides,
    SUM(CASE WHEN Cancelled_Rides_by_Customer = 1 THEN 1 ELSE 0 END) AS customer_cancellations,
    SUM(CASE WHEN Cancelled_Rides_by_Driver = 1 THEN 1 ELSE 0 END) AS driver_cancellations,
    SUM(CASE WHEN Incomplete_Rides = 1 THEN 1 ELSE 0 END) AS incomplete_rides,
    
    -- Completion rate
    ROUND(SUM(CASE WHEN Booking_Status = 'Completed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS completion_rate,
    
    -- Financial metrics
    SUM(Booking_Value) AS total_revenue,
    AVG(Booking_Value) AS avg_booking_value,
    
    -- Distance metrics
    SUM(Ride_Distance) AS total_distance,
    AVG(Ride_Distance) AS avg_distance,
    AVG(Price_Per_Km) AS avg_price_per_km,
    
    -- Ratings
    AVG(Driver_Ratings) AS avg_driver_rating,
    AVG(Customer_Rating) AS avg_customer_rating,
    
    -- Time metrics
    AVG(Avg_VTAT) AS avg_vehicle_arrival_time,
    AVG(Avg_CTAT) AS avg_customer_acceptance_time,
    
    -- Weekend vs weekday
    SUM(CASE WHEN Is_Weekend = 1 THEN 1 ELSE 0 END) AS weekend_rides,
    SUM(CASE WHEN Is_Weekend = 0 THEN 1 ELSE 0 END) AS weekday_rides,
    
    -- Peak vs off-peak
    SUM(CASE WHEN Is_Peak_Hour = 1 THEN 1 ELSE 0 END) AS peak_hour_rides,
    SUM(CASE WHEN Is_Peak_Hour = 0 THEN 1 ELSE 0 END) AS off_peak_rides
FROM `portfolioproject`.`uber_clean`
WHERE Booking_DateTime IS NOT NULL
GROUP BY `year_month`, Vehicle_Type
ORDER BY `year_month`, Vehicle_Type;

