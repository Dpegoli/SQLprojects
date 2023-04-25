SELECT * FROM Covid_Project.coviddeaths;
--select * from Covid_Project.covidvaccinations
--order by 3,4

-- select the data i want to use
SELECT location,date,total_cases,new_cases,total_deaths,population,continent FROM Covid_Project.coviddeaths;
order by 3,4

-- looking at total cases vs total deaths first im just as deathpercentage 
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Covid_Project.coviddeaths;
order by 3,4
-- likelihood of getting Covid ( alot of perecentage filtring will be done)..as DeathPercentage is new column   
-- looking at total cases vs total deaths first im just as deathpercentage ( filter in location for states)
SELECT location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM Covid_Project.coviddeaths
Where location like '%states%'
order by 3,4

-- looking for Total Cases Vs Population  as Case Percentage is new column 
-- shows what perecntage of population got covid
SELECT location,date,total_cases,population, (total_cases/population)*100 as CasePercentage
FROM Covid_Project.coviddeaths
Where location like '%states%'
order by 3,4

-- at this point im starting to think about how I can visualize the data and what will help too visualize my point. 

-- Looking at countries with highest infection rate comapred to popultion. I got rid of date cause its not date specific its OVERALL. looking at only the highest total cases so using MAX then grouping by 
-- group by population and location then order by PerecentPopulationInfection column desc to see highest 
SELECT location,population,Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfection
FROM Covid_Project.coviddeaths
-- Where location like '%states%'
Group continent, population
order by PercentPopulationInfection desc

-- showing the countries with highest death count per population
SELECT continent,Max(total_deaths) as TotalDeathCount
FROM Covid_Project.coviddeaths
group by continent 
order by TotalDeathCount desc

-- totaldeaths look off might have to CAST(Convert) to unsigned. to make sure the column got imported correctly 
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM Covid_Project.coviddeaths
Where trim(continent) = '' 
GROUP BY location 
ORDER BY TotalDeathCount DESC

-- I am noticing a issue with the data that columns got crossed location grouping continent where location reads continent name then Continent column reads continet name as well and where location is 
-- continent name the continent column has no data. So I fixed by reading in Where continent trim <> '' (Where trim(continent)<> '') if the data read in as NULL I would use 
-- (Where continent is not null) function.   


SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM Covid_Project.coviddeaths
Where trim(continent)<> ''
GROUP BY location 
ORDER BY TotalDeathCount DESC

-- BREAKING DOWN BY CONTINENT using = ''  equal to space. 

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM Covid_Project.coviddeaths
Where trim(continent) = '' 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Gloabal Numbers  by date 
Select date,SUM(new_cases) as total_cases, SUM(cast(new_deaths as unsigned)) as total_deaths, SUM(cast(new_deaths as unsigned))/SUM(New_Cases)*100 as DeathPercentage
FROM Covid_Project.coviddeaths
Where continent is null or trim(continent) = ''
group by date 
order by 1,2

-- Global NUmbers total 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as unsigned)) as total_deaths, SUM(cast(new_deaths as unsigned))/SUM(New_Cases)*100 as DeathPercentage
FROM Covid_Project.coviddeaths
Where continent is null or trim(continent) = ''
order by 1,2

-- joining tables by a inner join and using alias to shorten the table names  ( when I join and query through i specify what table i want from.  

Select *
FROM Covid_Project.coviddeaths dea
join Covid_Project.covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date    
    
-- both tables look to be joine dcorrectly 

-- looking at Total Population Vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,sum(cast(vac.new_vaccinations as unsigned)) OVER (Partition by dea.Location)
FROM Covid_Project.coviddeaths dea
join Covid_Project.covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date  
Where trim(dea.continent) <> '' 
order by 2,3   

-- Shows Percentage of Population that has recieved at least one Covid Vaccine using rolling 
-- using CTE.  
-- 'This code is creating a Common Table Expression (CTE) called PopvsVac that joins two tables (coviddeaths and covidvaccinations) on location and date columns and calculates the rolling sum of new vaccinations per location using the SUM() function with the OVER() clause. 
-- The RollingPeopleVaccinated column is calculated using the SUM() function with the CAST() function to convert the new_vaccinations column to an unsigned integer, and the OVER() clause to perform the sum for each location and order it by location and date.\n\n
-- The CTE also selects the continent, location, date, population, and new_vaccinations columns from the coviddeaths and covidvaccinations tables where the continent is not blank.\n\nFinally, the main query selects all columns from the PopvsVac CTE and 
-- adds a new column that calculates the percentage of people vaccinated per location by dividing the RollingPeopleVaccinated column by the population column and multiplying by 100.'

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as unsigned)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM Covid_Project.coviddeaths dea
join Covid_Project.covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where trim(dea.continent) <> '' 
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
-- TEMP TABLE had a little trouble with formating cause on int, non nulls, empty spaces ect...  
-- This code is inserting data into the PercentPopulationVaccinated table by selecting columns from two existing tables named coviddeaths and covidvaccinations.

-- breakdown of the code:

-- The INSERT INTO statement specifies the name of the table and the columns to be inserted.
-- The SELECT statement retrieves data from the coviddeaths and covidvaccinations tables, joined on the location and date columns.
-- The STR_TO_DATE function is used to convert the date column from the coviddeaths table to a valid datetime format.
-- The CAST function is used to convert the population column from the coviddeaths table to a decimal data type.
-- The SUM function is used to calculate a rolling sum of the new_vaccinations column from the covidvaccinations table, partitioned by the location column and ordered by the location and date columns. This value is inserted into the RollingPeopleVaccinated columnThe WHERE clause filters the data to only include rows where the population and new_vaccinations columns contain numeric values.
-- Overall, this code is inserting data into the PercentPopulationVaccinated table by selecting columns from two existing tables and transforming the data as necessary. 

INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y'), CAST(dea.population AS DECIMAL), vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Project.coviddeaths dea
JOIN Covid_Project.covidvaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.population REGEXP '^[0-9]+(\.[0-9]+)?$'
  AND vac.new_vaccinations REGEXP '^[0-9]+(\.[0-9]+)?$';



SELECT * FROM PercentPopulationVaccinated;


DROP VIEW IF EXISTS PercentPopulationVaccinated;

-- Creating View to store data for later visualizations changed name to Covidvaxx
-- This code creates a new view called "my_view_name" which selects certain columns from two tables (coviddeaths and covidvaccinations) and joins them together based on location and date. 
-- It also applies some formatting and calculations to the data using the STR_TO_DATE and CAST functions and the SUM window function. 
-- Finally, it includes a WHERE clause to filter out any rows where the population or new_vaccinations columns do not contain numeric values.

CREATE VIEW Covidvaxx AS 
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y') AS Date, CAST(dea.population AS DECIMAL) AS Population, vac.new_vaccinations AS New_vaccinations, 
  SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated 
FROM Covid_Project.coviddeaths dea 
JOIN Covid_Project.covidvaccinations vac 
ON dea.location = vac.location 
AND dea.date = vac.date 
WHERE dea.population REGEXP '^[0-9]+(\.[0-9]+)?$' 
AND vac.new_vaccinations REGEXP '^[0-9]+(\.[0-9]+)?$';



create view covidcontinents as 
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM Covid_Project.coviddeaths
Where trim(continent) = '' 
GROUP BY location
ORDER BY TotalDeathCount DESC
