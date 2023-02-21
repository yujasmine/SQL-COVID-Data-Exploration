SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4


-- Select data that we are going to be using
SELECT 
	location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT 
	location
	, date
	, total_cases,total_deaths
	, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' 
AND continent is not null
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of pupolation got Covid
SELECT 
	location
	, date
	, population
	, total_cases
	, (total_cases/population)*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at countries with Higest Infection Rate compared to Population
SELECT
	location
	, population
	, MAX(total_cases) AS highest_infaction_count
	, MAX((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC


-- Showing countries with Highest Death Count per Population
-- cast due to the data type
SELECT 
	location
	, MAX(cast(total_deaths as int)) AS total_death_counts
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_counts DESC

-- Let's break things down by continent
-- Showing continents with the Highest Death Counts per Population
SELECT 
	continent
	, MAX(cast(total_deaths as int)) AS total_death_counts
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_counts DESC

--Global Numbers by date
SELECT 
	date
	, SUM(new_cases) AS total_cases
	, SUM(cast(new_deaths as int)) AS total_deaths
	, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date 
ORDER BY 1,2

-- Total Death rate across the world
SELECT 
	SUM(new_cases) AS total_cases
	, SUM(cast(new_deaths as int)) AS total_deaths
	, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Popolation vs Vaccinations
-- Trying out Convert instead of cast, but still to change the data type
-- Partition by location so not all numbers add up only the same location add up
SELECT 
	dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations 
	, SUM(CONVERT(int, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
--	, (rolling_ppl_vac/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE
-- The total number of cols needs to be the same as the cols you select
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_ppl_vac)
AS
(
SELECT 
	dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations 
	, SUM(CONVERT(int, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
--	, (rolling_ppl_vac/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rolling_ppl_vac/population)*100
FROM popvsvac

-- Alternative option
-- TEMP table
DROP TABLE IF exists #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255)
, location nvarchar(255)
, date datetime
, population numeric
, new_vaccinations numeric
, rolling_ppl_vac numeric
)

INSERT INTO #percent_population_vaccinated
SELECT 
	dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations 
	, SUM(CONVERT(int, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
--	, (rolling_ppl_vac/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (rolling_ppl_vac/population)*100 AS rolling_vac_rate
FROM #percent_population_vaccinated


-- Creating View to store data for later visualization #1
CREATE VIEW percent_population_vaccinated AS 
SELECT 
	dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations 
	, SUM(CONVERT(int, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vac
--	, (rolling_ppl_vac/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM percent_population_vaccinated

-- Creating View to store data for later visualization #2
CREATE VIEW total_death_rate AS
SELECT 
	SUM(new_cases) AS total_cases
	, SUM(cast(new_deaths as int)) AS total_deaths
	, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null

-- Creating View to 
CREATE VIEW case_num_per_day AS 
SELECT 
	date
	, SUM(new_cases) AS total_cases
	, SUM(cast(new_deaths as int)) AS total_deaths
	, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date 
