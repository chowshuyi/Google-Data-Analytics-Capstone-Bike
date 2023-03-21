# Google-Data-Analytics-Capstone-Bike

This case study is part of the Google Data Analytics course.

I will be using the 6-steps of data analysis process for this project: **Ask**, **Prepare**, **Process**, **Analyze**, **Share** and **Act**.


### **STEP 1: ASK**

#### **Background**
Cyclistic is a bike-sharing company in Chicago. In 2016, they launched a successful bike-share offering program and have since then grown to a fleet of 5,824 bicycles that are geotracked and locked into a network of 692 stations across Chicago. The bikes can be unlocked from one station and returned to any other station in the system at any time. There are 2 types of customers: *casual riders* and *members*. Customers who purchase single-ride or full-day passes are referred to as casual riders; customers who purchase annual memberships are Cyclistic members.

#### **Business Task**
Analyze the pattern and differences between casual riders and members, to provide insights on converting casual riders into members.

#### **Business Questions**
1. How do annual members and casual riders use Cyclistic bikes differently?
2. Why would casual riders buy Cyclistic annual memberships?
3. How can Cyclistic use digital media to influence casual riders to become members?


### **STEP 2: PREPARE**

#### **Data Source and Specification**
The latest 12 months of data are taken from [Divvy Bike website](https://divvy-tripdata.s3.amazonaws.com/index.html). They are stored in CSV files by month.

#### **Data Credibility**
RELIABLE: The reliability of data is uncertain because the information of riders is removed due to privacy reasons.

ORIGINAL: The data is original as it's owned and collected by Divvy.

COMPREHENSIVE: The data is comprehensive as it contains information about casual riders and members, start and end timestamps of their trips, and start and end stations.

CURRENT: The data is fairly current and up to date as the data is collected from February 2022 to January 2023.

CITED: The data is cited as it’s owned and collected by Divvy.


### **STEP 3: PROCESS**

#### **Tools**
Excel and SQL are used for data transformation and cleaning, and Tableau is used for data visualization.

#### **Data Transformation and Cleaning**
A new column is created called *day_of_week* using the Excel formula "TEXT", for example:
```
=TEXT(C2,"dddd")
```
It will show the day of the date in column C as below:
![Capture](https://user-images.githubusercontent.com/127185901/224466667-4fe4497f-96b7-4844-a1ba-37bd1a14b87f.PNG)

All files were saved as Excel Workbook file type and renamed as "divvy-tripdata-yyyymm" so the files do not start with numbers.

All 12 files were imported to SQL Server and the below query was run to combine all 12 tables into one.
```sql
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
```
Then, the below query was run to remove any rows with NULL values. (Note: Before removing any rows with NULL values, we should always check if the NULL values are valid. If there is a reason for the attribute/column to have NULL values, we should keep it. However, for this project, they will be removed).
```sql
DELETE FROM divvy_tripdata
WHERE start_station_name IS NULL
	OR start_station_id IS NULL
	OR end_station_name IS NULL
	OR end_station_id IS NULL
	OR start_lat IS NULL
	OR start_lng IS NULL
	OR end_lat IS NULL
	OR end_lng IS NULL;
```
Rows with duplicated **ride_id** were also removed, since ride_id should be unique/distinct as new ride_id is generated with each new ride.
```sql
DELETE FROM divvy_tripdata
WHERE ride_id IN (
	SELECT ride_id
	FROM divvy_tripdata
	GROUP BY ride_id
	HAVING COUNT(*) > 1);
```
Rows with started time later than ended time were also removed using below query:
```sql
DELETE FROM divvy_tripdata
WHERE started_at > ended_at;
```
Rows with start station or end station name **Based - 2132 W Hubbard Warehouse** were removed.
```sql
DELETE FROM divvy_tripdata
WHERE start_station_name LIKE '%warehouse%'
	OR end_station_name LIKE '%warehouse%';
```


### **STEP 4: ANALYZE**

This is the step of analyzing the data. The full SQL script of the process can be found in [google-data-analytics-bike-sql.sql](https://github.com/chowshuyi/Google-Data-Analytics-Capstone-Bike/blob/main/google-data-analytics-bike-sql.sql).

The column **trip_duration** were added to the table using below query:
```sql
ALTER TABLE divvy_tripdata
ADD trip_duration INT;

UPDATE divvy_tripdata
SET trip_duration = DATEDIFF(minute, started_at, ended_at);
```
To calculate the percentage of member vs casual riders:
```sql
SELECT member_casual, COUNT(*) as count, COUNT(*) * 100 / SUM(COUNT(*)) OVER() as percentage
FROM divvy_tripdata
GROUP BY member_casual;
```
To calculate the average, min and max of the trip duration by rider type:
```sql
SELECT member_casual, AVG(trip_duration) AS average_trip_duration, MIN(trip_duration) AS min_trip_duration, MAX(trip_duration) AS max_trip_duration
FROM divvy_tripdata
GROUP BY member_casual;
```
To calculate the count of rider by type and weekday:
```sql
SELECT day_of_week, COUNT(*) as member_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY day_of_week
ORDER BY member_count DESC;

SELECT day_of_week, COUNT(*) as casual_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY day_of_week
ORDER BY casual_count DESC;
```
To calculate the count of rider by type and month:
```sql
SELECT month, COUNT(*) as member_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY month
ORDER BY member_count DESC;

SELECT month, COUNT(*) as casual_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY month
ORDER BY casual_count DESC;
```
To calculate the count of rider by type and start/end station:
```sql
SELECT TOP 10 start_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY start_station_name
ORDER BY station_count DESC;

SELECT TOP 10 end_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'member'
GROUP BY end_station_name
ORDER BY station_count DESC;

SELECT TOP 10 start_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY start_station_name
ORDER BY station_count DESC;

SELECT TOP 10 end_station_name, COUNT(*) AS station_count
FROM divvy_tripdata
WHERE member_casual = 'casual'
GROUP BY end_station_name
ORDER BY station_count DESC;
```


### **STEP 5: SHARE**

The full data visualization is available [here](https://public.tableau.com/app/profile/chow.shu.yi/viz/GoogleDABike/Dashboard1?publish=yes) in Tableau.

![Member vs Casual Riders](https://user-images.githubusercontent.com/127185901/226613189-4e776cee-0618-4da8-b603-91ae89c66dab.png)

From the above pie chart, we can see that 59.93% of the users are members and 40.07% of the users are casual riders. Although there are more members than casual riders, casual riders are still very close to 50%.
