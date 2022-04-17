/* Project Objectives
1. Which countries suffer more from covid?
	-> Worse death rates and infection rates
2. Does stricter policies lead to less suffering from covid?
*/

--Check the states of the data
SELECT *
FROM covid_cases

SELECT *
FROM population

SELECT *
FROM stringency_index

--Create total_cases and merge population
--Create a temp table to store the results for future analysis
DROP TABLE IF EXISTS #overall
CREATE TABLE #overall
  (location VARCHAR(50),
   date datetime,
   new_cases NUMERIC,
   cumu_cases NUMERIC,
   new_deaths NUMERIC,
   cumu_deaths NUMERIC,
   population NUMERIC)

INSERT INTO #overall
　　SELECT c.location,
　　　　 　 c.date,
　　　　 　 new_cases,
　　　　 　 SUM(new_cases) OVER(PARTITION BY c.location ORDER BY c.date) AS cumu_cases,
　　　　 　 new_deaths,
          SUM(CAST(new_deaths AS INT)) OVER(PARTITION BY c.location ORDER BY c.date) AS cumu_deaths,
	      population
　　FROM covid_cases AS c
　　INNER JOIN population AS p
  　　 ON c.location = p.location AND c.date = p.date

SELECT *
FROM #overall

--Look at the top 20 highest death rates.
SELECT TOP 20
       location, 
       MAX(cumu_deaths/cumu_cases)*100 AS max_death_rate
FROM #overall
WHERE cumu_cases > 10000　--When total cases are too few, the death rate is not statistically feasible
GROUP BY location
ORDER BY max_death_rate DESC

--Look at the top 20 lowest death rates
SELECT TOP 20
       location, 
       MAX(cumu_deaths/cumu_cases)*100 AS max_death_rate
FROM #overall
WHERE cumu_cases > 10000　--When total cases are too few, the death rate is not statistically feasible
GROUP BY location
ORDER BY max_death_rate

--Look at the top 20 highest infection rate countreis/areas.
SELECT TOP 20
       location,
	   MAX(cumu_cases/population) * 100 AS max_infection_rate
FROM #overall
GROUP BY location
ORDER BY max_infection_rate DESC

--Look at the top 20 lowest infection rate countries/regions
SELECT TOP 20
       location,
	   MAX(cumu_cases/population *100)AS max_infection_rate
FROM #overall
GROUP BY location
HAVING MAX(cumu_cases/population) IS NOT NULL
ORDER BY max_infection_rate

--Max infection rate per location for visulization
SELECT location,
	   MAX(cumu_cases/population*100) AS max_infection_rate
FROM #overall
GROUP BY location
HAVING MAX(cumu_cases/population) IS NOT NULL
ORDER BY max_infection_rate

--Look at Japan's death rate over time　- visulazation
SELECT date,
       cumu_deaths/cumu_cases * 100 AS jp_death_rate
FROM #overall
WHERE location = 'Japan' AND cumu_deaths/cumu_cases * 100 IS NOT NULL
ORDER BY jp_death_rate

--Look at Japan's infection rate over time - visulation
SELECT date,
       cumu_cases/population * 100 AS jp_infection_rate
FROM #overall
WHERE location = 'Japan' AND cumu_cases/population * 100 IS NOT NULL
ORDER BY jp_infection_rate DESC

------------------------------------------------------------------------------------
--Look at how strict the policy is in countries (for later visulazation)
SELECT c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
ORDER BY avg_stringency_index DESC

--Top 20 strict locations
SELECT TOP 20
       c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
ORDER BY avg_stringency_index DESC

--Top 20 loose locations
SELECT TOP 20
       c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
HAVING ROUND(AVG(stringency_index), 2) IS NOT NULL
ORDER BY avg_stringency_index

--Look at the overlapping percentege of the top 50 strict locations and the top lowest infection rates - 5 results
SELECT location
FROM (
SELECT TOP 50
       location,
	   MAX(cumu_cases/population) * 100 AS max_infection_rate
FROM #overall
GROUP BY location
HAVING MAX(cumu_cases/population) IS NOT NULL
ORDER BY max_infection_rate) AS sub1

INTERSECT

SELECT location
FROM (
SELECT TOP 50
       c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
ORDER BY avg_stringency_index DESC) AS sub2

--Look at the overlapping percentege of the top 50 strict locations and the 50 lowest death rates - 5 results
SELECT location
FROM (
SELECT TOP 50
       c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
ORDER BY avg_stringency_index DESC) AS sub3

INTERSECT

SELECT location
FROM (
SELECT TOP 50
       location, 
       MAX(cumu_deaths/cumu_cases)*100 AS max_death_rate
FROM #overall
WHERE cumu_cases > 10000　--When total cases are too few, the death rate is not statistically feasible
GROUP BY location
ORDER BY max_death_rate) AS sub4

--Look at the overlapping percentege of the top 50 loose locations and the 50 top infection rates - 9 results
SELECT location
FROM (
SELECT TOP 50
       c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
HAVING ROUND(AVG(stringency_index), 2) IS NOT NULL
ORDER BY avg_stringency_index
) AS sub5

INTERSECT

SELECT location
FROM (
SELECT TOP 50
       location,
	   MAX(cumu_cases/population) * 100 AS max_infection_rate
FROM #overall
GROUP BY location
ORDER BY max_infection_rate DESC
) AS sub6

--Look at the overlapping percentege of the top 50 loose locations and the 50 top death rates - 10 results
SELECT location
FROM (
SELECT TOP 50
       c.location,
       ROUND(AVG(stringency_index), 2) AS avg_stringency_index
FROM covid_cases c
INNER JOIN stringency_index s
  ON c.iso_code = s.iso_code AND c.date = s.date
GROUP BY location
HAVING ROUND(AVG(stringency_index), 2) IS NOT NULL
ORDER BY avg_stringency_index
) AS sub7

INTERSECT

SELECT location
FROM (
SELECT TOP 50
       location, 
       MAX(cumu_deaths/cumu_cases)*100 AS max_death_rate
FROM #overall
WHERE cumu_cases > 10000　--When total cases are too few, the death rate is not statistically feasible
GROUP BY location
ORDER BY max_death_rate DESC
) AS sub7

/*
Conclusion
Stricter policies does not naturally lead to less suffering from covid and vice versa.
But slight possibilites are stricter policies have a better chance to make things not going into the worst.
But this is not statistically confident to prove.
*/

