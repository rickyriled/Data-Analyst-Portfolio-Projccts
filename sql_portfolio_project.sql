/* Create and choose database to use */
CREATE DATABASE COVID;
USE COVID;

-- Loading in data --

/* Our two tables are `covid-death-header` and `covid-vac-header` ; 
	their table structures were built using the import wizard, then
    filled using the 'load data' command, with parsing specified for
    csv files */

LOAD DATA LOCAL INFILE '/Users/rickwilde/Desktop/covid-vac-data-2.csv' INTO TABLE COVID.`covid-vac-header`
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE '/Users/rickwilde/Desktop/covid-death-data-2.csv' INTO TABLE COVID.`covid-death-header`
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n';

/* examine covid death table */
SELECT continent, location
FROM COVID.`covid-death-header`;

/* examine covid vacination table, order by columns 3 & 4 
	(i.e. location and date) */
SELECT *
FROM COVID.`covid-vac-header`
ORDER BY 3,4 ;




-- exploring total cases/ total deaths/ rates across locations/ dates --

/* examine a subset of the death data */
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM  COVID.`covid-death-header`
ORDER BY 1,2;

/* looking at Total Cases vs Total Deaths as a percent */
SELECT Location, date, total_cases, total_deaths, 100*total_deaths/total_cases as death_percent
FROM  COVID.`covid-death-header`
WHERE location like '%states%'
ORDER BY 1,2;

/* Total Cases vs Total Deaths, but United States specifically */
SELECT Location, date, total_cases, total_deaths, 100*total_deaths/total_cases as death_percent
FROM  COVID.`covid-death-header`
WHERE location like '%states%'
ORDER BY 1,2;

/* looking at total cases vs. population in the states */
SELECT Location, date, population, 100*total_cases/population as case_to_pop_ratio
FROM COVID.`covid-death-header`
WHERE location like '%states%'
ORDER BY 1,2;

/* looking at countrys with highest Infection Rate compared to population */
SELECT Location, population, MAX(total_cases) AS max_total_cases, MAX(100*total_cases/population) AS max_case_pop_ratio
FROM COVID.`covid-death-header`
GROUP BY Location, population
ORDER BY 4 DESC;

/* looking at countrys with highest death Rate compared to population */
SELECT Location, population, MAX(total_deaths) AS max_total_deaths, MAX(100*total_deaths/population) AS max_death_pop_ratio
FROM COVID.`covid-death-header`
WHERE continent<>""
GROUP BY Location, population
ORDER BY 4 DESC;




-- explore how covid varied over the continents --

/* looking at total deaths across continents */
SELECT continent, SUM(total_deaths) AS TotContDeath
FROM COVID.`covid-death-header`
WHERE continent<>""
GROUP BY continent
ORDER BY TotContDeath DESC;

/* Examining new deaths per day vs. new cases per day  */ 
SELECT date, SUM(new_cases), SUM(new_deaths), 100*SUM(new_deaths)/SUM(new_cases) as NewDeathToCasesRatio
FROM COVID.`covid-death-header`
WHERE continent<>""
GROUP By date
order by 1,2;

/* Rolling sum over of new vacinations over time by location  */ 
SELECT death.continent, death.Location, death.date, death.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY death.Location  ORDER BY death.Location, death.date) as RollingVacCount
FROM COVID.`covid-death-header` as death
	JOIN COVID.`covid-vac-header` as vac
	ON death.Location = vac.Location
    AND death.date = vac.date
WHERE death.continent<>""
ORDER BY 2,3;




-- creating data to export to Tableau--

/* Create a temporary table for rolling sum of new vacinations*/
CREATE TEMPORARY TABLE POPVAC (
SELECT death.continent, death.Location, death.date, death.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY death.Location  ORDER BY death.Location, death.date) as RollingVacCount
FROM COVID.`covid-death-header` as death
	JOIN COVID.`covid-vac-header` as vac
	ON death.Location = vac.Location
    AND death.date = vac.date
WHERE death.continent<>""
);

/* Creating view of rolling sum of new vacinations */
CREATE VIEW PercentPop as (
SELECT death.continent, death.Location, death.date, death.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY death.Location  ORDER BY death.Location, death.date) as RollingVacCount
FROM COVID.`covid-death-header` as death
	JOIN COVID.`covid-vac-header` as vac
	ON death.Location = vac.Location
    AND death.date = vac.date
WHERE death.continent<>"");




