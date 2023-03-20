-- 1. Create a new table that combines all 12 tables

SELECT *
INTO divvy_tripdata
FROM [dbo].[divvy-tripdata-202202]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202203]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202204]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202205]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202206]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202207]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202208]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202209]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202210]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202211]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202212]
UNION
SELECT *
FROM [dbo].[divvy-tripdata-202301];


-- 2. Remove any rows with NULL values

SELECT COUNT(*)
FROM divvy_tripdata; -- From this query we can see that the total number of rows is 5754248.

SELECT COUNT(*)
FROM divvy_tripdata
WHERE start_station_name IS NULL
	OR start_station_id IS NULL
	OR end_station_name IS NULL
	OR end_station_id IS NULL
	OR start_lat IS NULL
	OR start_lng IS NULL
	OR end_lat IS NULL
	OR end_lng IS NULL; -- From this query we can see that the number of rows with any NULL values is 1316732.

DELETE FROM divvy_tripdata
WHERE start_station_name IS NULL
	OR start_station_id IS NULL
	OR end_station_name IS NULL
	OR end_station_id IS NULL
	OR start_lat IS NULL
	OR start_lng IS NULL
	OR end_lat IS NULL
	OR end_lng IS NULL;

SELECT COUNT(*)
FROM divvy_tripdata; -- New total number of rows is 4437516 after removing NULL values.


-- 3. Calculate the trip duration and add the new column into the table

SELECT started_at, ended_at, DATEDIFF(minute, started_at, ended_at) AS trip_duration
FROM divvy_tripdata;

ALTER TABLE divvy_tripdata
ADD trip_duration INT;

UPDATE divvy_tripdata
SET trip_duration = DATEDIFF(minute, started_at, ended_at);


-- 4. Find data anomalies

SELECT DISTINCT member_casual, COUNT(member_casual) AS member_casual_count
FROM divvy_tripdata
GROUP BY member_casual;

SELECT DISTINCT rideable_type, COUNT(rideable_type) AS bike_count
FROM divvy_tripdata
GROUP BY rideable_type;

SELECT ride_id, COUNT(ride_id)
FROM divvy_tripdata
GROUP BY ride_id
HAVING COUNT(ride_id) > 1; -- From this query we can see that some ride_id are duplicated.

SELECT *
FROM divvy_tripdata
WHERE ride_id IN (
	SELECT ride_id
	FROM divvy_tripdata
	GROUP BY ride_id
	HAVING COUNT(*) > 1); -- This query shows the details of duplicated ride_id.

-- 4(a). Remove rows with duplicated ride_id (ride_id should be unique/distinct as new ride_id is generated with each new ride)

DELETE FROM divvy_tripdata
WHERE ride_id IN (
	SELECT ride_id
	FROM divvy_tripdata
	GROUP BY ride_id
	HAVING COUNT(*) > 1);

SELECT COUNT(*)
FROM divvy_tripdata; -- New total number of rows is 4437498 after removing duplicated ride_id.

SELECT *
FROM divvy_tripdata
WHERE started_at > ended_at
ORDER BY trip_duration; -- 59 rows with started time is greater than ended time.

-- 4(b). Remove rows with started time later than ended time

DELETE FROM divvy_tripdata
WHERE started_at > ended_at;

SELECT COUNT(*)
FROM divvy_tripdata; -- New total number of rows is 4437439 after removing rows with started time later than ended time.

-- 4(c). Remove rows with start station or end station name "Base - 2132 W Hubbard Warehouse"

SELECT *
FROM divvy_tripdata
WHERE start_station_name LIKE '%warehouse%'
	OR end_station_name LIKE '%warehouse%';

DELETE FROM divvy_tripdata
WHERE start_station_name LIKE '%warehouse%'
	OR end_station_name LIKE '%warehouse%';

SELECT COUNT(*)
FROM divvy_tripdata; -- New total number of rows is 4437113 after removing rows with start station or end station name "Base - 2132 W Hubbard Warehouse".


-- 5. Add a new column "month" to the table

SELECT started_at, ended_at, DATENAME(month, started_at) AS month
FROM divvy_tripdata;

ALTER TABLE divvy_tripdata
ADD month nvarchar(100);

UPDATE divvy_tripdata
SET month = DATENAME(month, started_at);


-- 6. Create summary statistics for the table

-- 6(a). Member vs casual riders

SELECT member_casual, COUNT(*) as count, COUNT(*) * 100 / SUM(COUNT(*)) OVER() as percentage
FROM divvy_tripdata
GROUP BY member_casual;

-- 6(b). Calculate average, min and max of trip duration by rider type

SELECT member_casual, AVG(trip_duration) AS average_trip_duration, MIN(trip_duration) AS min_trip_duration, MAX(trip_duration) AS max_trip_duration
FROM divvy_tripdata
GROUP BY member_casual;

-- 6(c). Calculate count of rider type by weekday

SELECT day_of_week, COUNT(*) as member_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY day_of_week
ORDER BY member_count DESC; -- Tuesday has the hightest count for members.

SELECT day_of_week, COUNT(*) as casual_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY day_of_week
ORDER BY casual_count DESC; -- Saturday has the highest count for casual riders.

-- 6(d). Calculate count of rider type by month

SELECT month, COUNT(*) as member_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY month
ORDER BY member_count DESC; -- August has the highest count members.

SELECT month, COUNT(*) as casual_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY month
ORDER BY casual_count DESC; -- July has the highest count for casual riders.

-- 6(e). Calculate count of rider type by start/end station

SELECT TOP 10 start_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY start_station_name
ORDER BY station_count DESC; -- Kingsbury St & Kinzie St is the most popular pick up station for members.

SELECT TOP 10 end_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY end_station_name
ORDER BY station_count DESC; -- Kingsbury St & Kinzie St is also the most popular drop off station for members.

SELECT TOP 10 start_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY start_station_name
ORDER BY station_count DESC; -- Streeter Dr & Grand Ave is the most popular pick up station for casual riders.

SELECT TOP 10 end_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY end_station_name
ORDER BY station_count DESC; -- Streeter Dr & Grand Ave is also the most popular drop off station for casual riders.


-- 7. Create view for visualization

CREATE VIEW new_divvy_tripdata AS
SELECT member_casual, month, day_of_week, start_station_name, end_station_name, start_lat, start_lng, end_lat, end_lng, trip_duration
FROM divvy_tripdata
WHERE trip_duration <> 0;

SELECT *
FROM new_divvy_tripdata;
