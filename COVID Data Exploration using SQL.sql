--Corona Virus Data Exploration Using SQL.

--Skills Used: Aggregate Functions, JOINS, CTE, Temp Tables, Windows Functions, ROLLUP and Converting Data Types.


SELECT *
FROM [Project 1].dbo.CovidDeaths
ORDER BY 3,4

--Select data that we need for the next few queries.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Project 1].dbo.CovidDeaths
ORDER BY 3,4

--Shows the death percentage of India over a range of time.
SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS Death_Percentage
FROM [Project 1].dbo.CovidDeaths
WHERE location = 'India'
ORDER BY 2

--Shows the percentage of people infected by Covid in India.
SELECT location, date, total_cases, total_deaths, population, (total_cases/Population)*100 AS Percent_Infected
FROM [Project 1].dbo.CovidDeaths
WHERE location = 'India'
ORDER BY 2

--Shows the days on which the highest percentage of the population was infected and the number of deaths on that day.
SELECT location, date, new_cases, new_deaths, population, (new_cases/Population)*100 AS Percent_Infected_PerDay
FROM [Project 1].dbo.CovidDeaths
WHERE location = 'India'
ORDER BY Percent_Infected_PerDay DESC

--Countries with the highest Infection rates compared to population.
SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/Population))*100 AS Percent_Infected
FROM [Project 1].dbo.CovidDeaths
GROUP BY location,population
ORDER BY Percent_Infected DESC

--Countries with highest death count per population.
SELECT location, MAX(cast(total_deaths AS int)) AS Total_Death_Count
FROM [Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

--Continents with the highest death count per population.
SELECT continent, MAX(CAST(total_deaths AS int)) AS Total_Death_Count_ByContinent
FROM [Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count_ByContinent DESC

--Looking at the Global Numbers.
SELECT SUM(new_cases) AS Total_Cases,SUM(CAST(new_deaths AS int)) AS Total_Deaths,SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM [Project 1].dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Looking at the Daily data of Vaccinations in India .
SELECT location, date, SUM(CAST(people_vaccinated AS int)) AS Total_Vaccinated
FROM [Project 1].dbo.CovidVaccinations
WHERE  location= 'India'
GROUP BY location,date 
ORDER BY date DESC


--Percentage of Population that has recieved at least one Covid vaccine.
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(int,v.new_vaccinations)) 
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS People_Vaccinated,(people_vaccinated/d.population)*100 AS Percentage_Vaccinated
FROM [Project 1].dbo.CovidDeaths d
JOIN [Project 1].dbo.CovidVaccinations v
ON d.date=v.date AND d.location=v.location
WHERE d.continent IS NOT NULL
ORDER BY 2,3

--Looking at the percent of population who are fully vaccinated.
SELECT DISTINCT d.date,d.total_cases,d.population, v.people_fully_vaccinated,(v.people_fully_vaccinated/d.population)*100 AS Percentage_fully_Vaccinated
FROM [Project 1].dbo.CovidDeaths d
JOIN [Project 1].dbo.CovidVaccinations v
ON d.date=v.date AND d.location=v.location
WHERE d.location = 'India' AND people_fully_vaccinated IS NOT NULL
ORDER BY d.date

--Using CTE to perform calculations.
With PopulationVSVaccination(continent,location,date,population,new_vaccinations,People_Vaccinated)
AS
(
	SELECT DISTINCT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(int,v.new_vaccinations)) 
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS People_Vaccinated
	FROM [Project 1].dbo.CovidDeaths d
	JOIN [Project 1].dbo.CovidVaccinations v
	ON d.date=v.date AND d.location=v.location
	WHERE d.continent IS NOT NULL
	--ORDER BY 2,3
)
SELECT *,(people_vaccinated/population)*100 AS Percentage_Vaccinated
FROM PopulationVSVaccination
WHERE location = 'India'


--Creating a temporary table.
DROP TABLE IF EXISTS Percent_Vaccinated
CREATE TABLE Percent_Vaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	People_vaccinated numeric
)
INSERT INTO Percent_Vaccinated
SELECT DISTINCT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(int,v.new_vaccinations)) 
	OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS People_Vaccinated
FROM [Project 1].dbo.CovidDeaths d
JOIN [Project 1].dbo.CovidVaccinations v
	ON d.date=v.date AND d.location=v.location
WHERE d.continent IS NOT NULL and new_vaccinations IS NOT NULL
	--ORDER BY 2,3

SELECT *
FROM Percent_Vaccinated

--Using ROLLUP function to find the summary output.
SELECT location,SUM(CONVERT(bigint,people_fully_vaccinated)) AS Total_Vaccinated
FROM [Project 1].dbo.CovidVaccinations 
GROUP BY location WITH ROLLUP

--Creating a View.
CREATE VIEW Population_Vaccinated_Percentage
AS
	SELECT DISTINCT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(int,v.new_vaccinations)) 
		OVER(PARTITION BY d.location ORDER BY d.location, d.date) AS People_Vaccinated
	FROM [Project 1].dbo.CovidDeaths d
	JOIN [Project 1].dbo.CovidVaccinations v
		ON d.date=v.date AND d.location=v.location
	WHERE d.continent IS NOT NULL and new_vaccinations IS NOT NULL
	--ORDER BY 2,3
