--List of timezones
SELECT * FROM pg_timezone_names

--Change the timezone to GMT-5
ALTER DATABASE divvybikes SET timezone to 'America/Chicago'

-- See the columns in the dataset
SELECT * FROM divvybikes_2016,divvy_stations
LIMIT 5
SELECT * FROM divvy_stations
WHERE user_type = 'Subscriber' AND birthyear IS NULL
LIMIT 1000
	SELECT * FROM divvy_stations
LIMIT 5

SELECT user_type, COUNT(*)
FROM divvybikes_2016 a
WHERE NOT (a.gender IS NULL OR  a.birthyear IS NULL)
GROUP BY 1

SELECT gender, COUNT(*)
FROM divvybikes_2016
WHERE gender IS NOT NULL
GROUP BY 1

SELECT DISTINCT gender, COUNT(*) OVER (PARTITION BY user_type) FROM divvybikes_2016
WHERE gender is NOT NULL
/*Some null values observed in the gender and birthyear column. Further checks for null values have been
conducted in Python, and there are 858,429 null values in the Gender column, and 858,125 null values in the
birthyear column. No other null values have been observed in the other columns*/

/*Find out the dock station with the least amt of bikes, most amt of bikes, total amt of bikes available
and total amt of dock stations*/
SELECT 
	MIN(docks), MAX(docks), SUM(docks), COUNT(docks) 
FROM divvy_stations

--Check for the longest ride duration expressed in seconds
SELECT trip_id, bikeid, EXTRACT(EPOCH FROM end_time - start_time) AS duration
FROM divvybikes_2016
ORDER BY duration DESC
LIMIT 1

/*Explore the gender diversity of Divvybike users, here we exclude NULL entries and make the assumption that
there is an equal numbers of users who did not wish to reveal their gender*/
SELECT gender, COUNT(*) AS number_of_users
FROM divvybikes_2016
WHERE gender IS NOT NULL
GROUP BY 1

--Count the total number of male/female customers/subscribers
SELECT
    (
        Select
            COUNT(gender)
        from divvybikes_2016
        where gender = 'Male' AND user_type = 'Customer'
     ) as Total_Male_Customers
    ,(
        Select
            COUNT(gender)
        from divvybikes_2016
        where gender = 'Female' AND user_type = 'Customer'
     ) as Total_Female_Customers,
	 (
        Select
            COUNT(gender)
        from divvybikes_2016
        where gender = 'Male' AND user_type <> 'Customer'
     ) as Total_Male_Subscribers,
	 (
        Select
            COUNT(gender)
        from divvybikes_2016
        where gender = 'Female' AND user_type <> 'Customer'
     ) as Total_Female_Subscribers
FROM divvybikes_2016
LIMIT 1

--Count of rider's ages, order by the age with the highest count (excluding nulls)
SELECT (2016 - birthyear), COUNT(*) AS age
FROM divvybikes_2016
WHERE (2016 - birthyear) IS NOT NULL
GROUP BY 1
ORDER BY 2 desc

--Average age of riders = 36
SELECT ROUND(AVG(2016 - birthyear),0) AS average_age_of_users
FROM divvybikes_2016

SELECT 
	DATE_PART('doy',start_time) AS day_of_mth
FROM divvybikes_2016

--Let's look at the number of riders in each age group. To be further explored
SELECT
	age_group,
	COUNT(*)
FROM
	(SELECT
	2022 - birthyear,
	CASE
	 	WHEN (2022 - birthyear) >= 50 AND (2022 - birthyear) < 60 THEN '50 and above'
		WHEN (2022 - birthyear) >= 40 AND (2022 - birthyear) < 50 THEN '40 and above'
		WHEN (2022 - birthyear) >= 30 AND (2022 - birthyear) < 40 THEN '30 and above'
		WHEN (2022 - birthyear) >= 20 AND (2022 - birthyear) < 30 THEN '20 and above'
		ELSE 'All others'
	END AS age_group FROM divvybikes_2016 WHERE birthyear IS NOT NULL) AS tmp
GROUP BY 1

--Next, let's look at the number of customers in each user_type. 
SELECT user_type, COUNT(*)
FROM divvybikes_2016
GROUP BY 1


SELECT * FROM divvy_stations

SELECT
	TO_CHAR(start_time,'Month') test, COUNT(trip_id)
	FROM divvybikes_2016
	GROUP BY 1
	ORDER BY 2 DESC
	
SELECT
	TO_CHAR(start_time,'Day') test, COUNT(trip_id)
	FROM divvybikes_2016
	GROUP BY 1
	
SELECT
	date_trunc(start_time,'HH24') test2, COUNT(trip_id)
	FROM divvybikes_2016
	GROUP BY 1
	

	
--Finding the shortest, average and longest ride durations
SELECT
	MIN(end_time - start_time), MAX(end_time - start_time), AVG(end_time - start_time)
	FROM divvybikes_2016

--Check for the most number of rides at different times of the day
SELECT
	date_trunc('week',start_time), COUNT(trip_id)
	FROM divvybikes_2016
	WHERE user_type = 'Customer'
	GROUP BY date_trunc('week',start_time)
	ORDER BY 2 DESC
	LIMIT 20

SELECT
	date_trunc('month',start_time), COUNT(trip_id)
	FROM divvybikes_2016
	WHERE user_type = 'Customer'
	GROUP BY date_trunc('month',start_time)
	ORDER BY 2 DESC
	LIMIT 20

SELECT
	date_trunc('hour',start_time), COUNT(trip_id)
	FROM divvybikes_2016
	WHERE user_type = 'Customer'
	GROUP BY date_trunc('hour',start_time)
	ORDER BY 2 DESC
	LIMIT 20

SELECT
	start_time, COUNT(trip_id)
	FROM divvybikes_2016
	GROUP by 1
	ORDER BY 2
	
/*SELECT
    to_char(start_time,'Month') AS month, to_char(date_trunc('hour', start_time), 'HH12:MI:SS AM') || ' - ' || to_char(date_trunc('hour', start_time)  + interval '1 hour', 'HH12:MI:SS AM') AS time_of_day,
    COUNT(trip_id) AS number_of_cyclists
FROM 
    divvybikes_2016
WHERE
	user_type = 'Customer'
GROUP BY 2,1
ORDER BY 3 DESC*/ --May further explore this query in the future.

--Calculate distance travelled
SELECT
	a.start_time,
	a.end_time,
	a.start_station_id,
	a.end_station_id,
	bs1.latitude AS lat1, -- Latitude of the start station
	bs1.longitude AS lon1, --Longitude of the start station
	bs2.latitude AS lat2, -- Latitude of the end station
	bs2.longitude AS lon2, --Longitude of the end station
	CAST(1.60934 * (SQRT(POW(69.1 * (bs1.latitude::float -  bs2.latitude::float), 2) + 
    POW(69.1 * (bs2.longitude::float - bs1.longitude::float) * COS(bs1.latitude::float / 57.3), 2))
) AS DECIMAL(4,2)) km_traveled
FROM
	divvybikes_2016 AS a
JOIN
	divvy_stations bs1 ON a.start_station_id = bs1.id
JOIN
	divvy_stations bs2 ON a.end_station_id = bs2.id
WHERE CAST(1.60934 * (SQRT(POW(69.1 * (bs1.latitude::float -  bs2.latitude::float), 2) + 
    POW(69.1 * (bs2.longitude::float - bs1.longitude::float) * COS(bs1.latitude::float / 57.3), 2))
) AS DECIMAL(4,2)) <> 0 --Don't want null values
ORDER BY km_traveled DESC

---
SELECT
	AVG(CAST(1.60934 * (SQRT(POW(69.1 * (bs1.latitude::float -  bs2.latitude::float), 2) + 
		POW(69.1 * (bs2.longitude::float - bs1.longitude::float) * COS(bs1.latitude::float / 57.3), 2))
	) AS DECIMAL(4,2))) km_traveled
	FROM
		divvybikes_2016 AS a
	JOIN
		divvy_stations bs1 ON a.start_station_id = bs1.id
	JOIN
		divvy_stations bs2 ON a.end_station_id = bs2.id
	WHERE CAST(1.60934 * (SQRT(POW(69.1 * (bs1.latitude::float -  bs2.latitude::float), 2) + 
    POW(69.1 * (bs2.longitude::float - bs1.longitude::float) * COS(bs1.latitude::float / 57.3), 2))
) AS DECIMAL(4,2)) <> 0 --Don't want null values

SELECT MAX(end_time - start_time) AS duration
FROM divvybikes_2016
WHERE user_type = 'Subscriber'

--Check the top 10 dropoff dock stations by both customers and subscribers.
SELECT *
FROM (SELECT
	a.end_station_id,
	b.name,
	COUNT(a.end_station_id),
	'Subscriber'
FROM
	divvybikes_2016 a
JOIN
	divvy_stations b ON a.end_station_id = b.id
WHERE a.user_type='Subscriber'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10) AS temp1
UNION ALL
SELECT *
FROM (SELECT
	a.end_station_id,
	b.name,
	COUNT(a.end_station_id),
	  'Customer'
FROM
	divvybikes_2016 a
JOIN
	divvy_stations b ON a.end_station_id = b.id
WHERE a.user_type='Customer' 
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10) AS temp2
