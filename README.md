# Google-Data-Analytics-Capstone-Bike

This case study is part of the Google Data Analytics course.

I will be using the 6-steps of data analysis process for this project: **Ask**, **Prepare**, **Process**, **Analyze**, **Share** and **Act**.


### **STEP 1: ASK**

#### **Background**
Cyclistic (a fictional company name) is a bike-sharing company in Chicago. In 2016, they launched a successful bike-share offering program and have since then grown to a fleet of 5,824 bicycles that are geotracked and locked into a network of 692 stations across Chicago. The bikes can be unlocked from one station and returned to any other station in the system at any time. There are 2 types of customers: *casual riders* and *members*. Customers who purchase single-ride or full-day passes are referred to as casual riders; customers who purchase annual memberships are Cyclistic members.

#### **Business Task**
Analyze the pattern and differences between casual riders and members, to provide insights on converting casual riders into members.

#### **Business Questions**
1. How do annual members and casual riders use Cyclistic bikes differently?
2. Why would casual riders buy Cyclistic annual memberships?
3. How can Cyclistic use digital media to influence casual riders to become members?


### **STEP 2: PREPARE**

#### **Data Source and Specification**
The latest 12 months of data are taken from the [Divvy Bike website](https://divvy-tripdata.s3.amazonaws.com/index.html). They are stored in CSV files by month.

#### **Data Credibility**
RELIABLE: The reliability of data is uncertain because the information of riders is removed due to privacy reasons.

ORIGINAL: The data is original as it's owned and collected by Divvy.

COMPREHENSIVE: The data is comprehensive as it contains information about casual riders and members, start and end timestamps of their trips, and start and end stations.

CURRENT: The data is current and up to date as the data is collected from February 2022 to January 2023.

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
Rows with duplicated **ride_id** were also removed, since ride_id should be unique/distinct as a new ride_id is generated with each new ride.
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

![Member vs Casual Riders](https://user-images.githubusercontent.com/127185901/226901178-868f0124-2027-4af5-b619-c04b05c3bdc6.png)

59.93% of the users are members and 40.07% are casual riders. Although there are more members than casual riders, casual riders are still close to 50%.

![Trip Duration by Weekday](https://user-images.githubusercontent.com/127185901/227482373-e9e9e70e-f886-436e-894e-1aa48712b502.png)

Looking at the total level, casual riders have longer trip duration than members during weekends, while there is not much difference in trip duration between casual riders and members during weekdays. However, when looking at the average level, casual riders have significantly longer trip duration than members throughout the week.

![Rider Type by Month](https://user-images.githubusercontent.com/127185901/226901302-afdc4f00-2f93-4c86-b325-2d845300bf61.png)

Both casual riders and members have a similar trend, with the Summer months (June-August) having a higher number of rides than other months.

![Rider Type by Weekday](https://user-images.githubusercontent.com/127185901/226901265-69641f6b-40ec-4938-b29f-72501a157e86.png)

Casual riders have a higher number of rides during weekends while members have a higher number of rides during weekdays.

![Count of Rides by Time](https://user-images.githubusercontent.com/127185901/227222375-f01372ae-1228-4da3-bf77-76132d4c9924.png)

For members, the count of rides peaked at 8 AM and 7 PM throughout the day. Whereas, for casual riders, the count of rides gradually increased and peaked at 5 PM.

![Top 15 Pick Up Stations](https://user-images.githubusercontent.com/127185901/226901340-09563cd0-aa1d-46eb-87cc-7a932dc4e8fd.png)
![Top 15 Drop Off Stations](https://user-images.githubusercontent.com/127185901/226901362-940b8d94-27e6-40d7-8fa1-6f4a5f960900.png)

The most popular pick up and drop off station for casual riders is *Streeter Dr & Grand Ave* while the most popular pick up and drop off station for members is *Kingsbury St Kinzie St*.

### **STEP 6: ACT**

In this step, we will bring back the 3 business questions.

1. How do annual members and casual riders use Cyclistic bikes differently?

On average, casual riders spend longer time than annual members on their bike trips. Also, casual riders have a higher number of rides during weekends while annual members have a higher number of rides during weekdays. This could suggest that most casual riders ride as a leisure activity during weekends, or to hang out with friends or family, hence the trip duration is longer. Whereas most annual members ride to commute to work during weekdays, hence the trip duration is shorter. This is also supported by "Count of Rides by Time" graph where the count of rides spiked up at 8 AM (start work) and 5 PM (get off work) for members, while the count of rides gradually increased for casual riders.

2. Why would casual riders buy Cyclistic annual memberships?

Upon inspecting the Divvy [website](https://divvybikes.com/pricing) about the details of different passes and memberships, we can see that the [Day Pass](https://divvybikes.com/pricing/day-pass) costs $16.50 per day with unlimited 3-hour rides for 24 hours. However, for [Annual Membership](https://divvybikes.com/pricing/annual), it costs $130.90 per year with only 45 minutes per ride. We can conclude that casual riders are long-trip riders and members are short-trip riders. It's most likely that casual riders would buy Cyclistic annual memberships when they no longer cycle as a leisure activity, but as a means to commute to work instead.

3. How can Cyclistic use digital media to influence casual riders to become members?

We would need more demographic information on the riders and their preferred digital media. According to [Khoros](https://khoros.com/resources/social-media-demographics-guide#which-social-media-networks-should-your-business-prioritize), TikTok users spend 95 minutes per day on the platform and open it 8 times a day. 18-24 years old occupied the highest percentage which is 39.91%. In this case, Cyclistic could target users aged 18 to 24 on TikTok to promote their business.

#### **Recommendations**

* Provide weekend-only annual membership with unlimited 3-hour rides for riders that prefer going out during weekends.
* Provide annual membership with 3 hours or more per ride for riders that prefer longer trips for any day.
* Conduct a survey to collect feedback from annual members on the reasons for becoming members and from casual riders on the reasons for not becoming members along with their demographic information for further analysis.
