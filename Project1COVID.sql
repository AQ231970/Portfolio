
Select *
From PortfolioProject_I..['CovidDeaths']
order by 3,4

Select *
From PortfolioProject_I..['CovidVaccinations']
order by 3,4

-- Select data we are going to be using 

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject_I..['CovidDeaths']
order by 1,2

-- Total Cases against Total Deaths 

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathsPercentage
From PortfolioProject_I..['CovidDeaths']
Where location = 'Canada'
order by 1,2

-- DeathsPercentage is the likelihood of death by contracting the virus at a given date, in Canada.

-- Total Cases vs Population 
Select location, date, total_cases, population, (total_cases/population)*100 as CasePercentage
From PortfolioProject_I..['CovidDeaths']
Where location = 'Canada'
order by 1,2
-- As of November 25 2022, ~11.52 % of the Canadian population has a reported case of covid. 

-- What countries have the highest infection rate by population ?
Select location, MAX(total_cases) AS MaxInfectionCount, population, Max(total_cases)/population*100 as CasePercentage
From PortfolioProject_I..['CovidDeaths']
GROUP BY location, population
order by CasePercentage DESC

-- Which countries exhibited highest death count by population?
Select location, MAX(cast(total_deaths as int)) AS MaxDeathCount
From PortfolioProject_I..['CovidDeaths']
GROUP BY location
order by MaxDeathCount DESC
-- small issue with locations: don't want to include "world" or whole continents or subregions like "africa" or "north america"
Select location, MAX(cast(total_deaths as int)) AS MaxDeathCount
From PortfolioProject_I..['CovidDeaths'] where continent is not NULL
GROUP BY location
order by MaxDeathCount DESC

-- Break down by continent 
Select location, MAX(cast(total_deaths as int)) AS MaxDeathCount
From PortfolioProject_I..['CovidDeaths'] where continent is NULL
GROUP BY location
order by MaxDeathCount DESC
--*the reason I selected NULL values for continent is because wherever the location is a continent, the numbers for that CONTINENT correspond under total_deaths (and consequently, maxdeathcount). I don't want to count those continent values under 'continent' because that is specifying for a specific location, and I will only see maximum death count of a spcific location rather than the continent as a whole.

-- Which continents have the highest death counts? (incorrect method)
Select continent, MAX(cast(total_deaths as int)) as Maxdeathcount
From PortfolioProject_I..['CovidDeaths'] where continent is not NULL
Group by continent
order by Maxdeathcount
-- the problem with the above is that, wherever continent is not null, is data for specific regions/countries. The resulting table will thereby give maxdeathcount 
--values of the region/country in that continent with the highest death counts, as opposed to the max death count in the continent as a whole. 

-- GLOBAL NUMBERS (excluding location, continent, etc.)

Select date, SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathsPercentage
From PortfolioProject_I..['CovidDeaths'] 
where continent is not NULL
group by date
order by 1,2

-- SUM(new_cases) adds up to result in total case number. 'cast(new_deaths as int)' bc new_deaths is an nvarchar data type

--Join tables
Select *
From PortfolioProject_I..['CovidVaccinations'] dea
Join PortfolioProject_I..['CovidDeaths'] vac
On dea.location = vac.location
and dea.date = vac.date

-- Comparing Total Population and Vaccinations on a Global Scale
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.date) as SubseqPeopleVaccinated
--, (SubseqPeopleVaccinated/dea.population)*100 as PercentpplVaccinated 
From PortfolioProject_I..['CovidDeaths'] dea
Join PortfolioProject_I..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not NULL
--order by 2,3

--** new_vaccinations is the number of new vaccines given out per day (also new_vaccines is a nvarchar so we use bigint due to the extent of the values),  
-- USE a CTE **ensure the number of columns listed in the CTE is same ** 
with PopulationvsVaccinations (Continent, Location, Date, Population, new_vaccinations, SubseqPeopleVaccinated) as (Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.date) as SubseqPeopleVaccinated 
From PortfolioProject_I..['CovidDeaths'] dea
Join PortfolioProject_I..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not NULL
) Select *, (SubseqPeopleVaccinated/Population)*100 as percentvaccinatedglobal
From PopulationvsVaccinations

--Maximum vaccinations by population
with PopulationvsVaccinations (Continent, Location, Population, new_vaccinations, MaxPeopleVaccinated) as 
(select dea.continent, dea.location, dea.population, vac.new_vaccinations
, MAX(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location) as MaxPeopleVaccinated
From PortfolioProject_I..['CovidDeaths'] dea
Join PortfolioProject_I..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not NULL
) select *, (MaxPeopleVaccinated/population)*100 as maxpercentglobal
from PopulationvsVaccinations

-- CREATING A  TEMP TABLE **remember to specify the data types
--**DROP TABLE if exists #PERCENTPOPVACCD if issues arise from making alterations to temp table 

DROP Table if exists #PERCENTPOPVACCD
CREATE TABLE #PERCENTPOPVACCD 
(
Continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, SubseqPeopleVaccinated numeric)

INSERT INTO #PERCENTPOPVACCD
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.date) as SubseqPeopleVaccinated
--, (SubseqPeopleVaccinated/dea.population)*100 as PercentpplVaccinated 
From PortfolioProject_I..['CovidDeaths'] dea
Join PortfolioProject_I..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not NULL

select *, (SubseqPeopleVaccinated/population)*100
from #PERCENTPOPVACCD

--create a view for future data visualization and simpler querying
create view PERCENTPOPVACCD as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, dea.date) as SubseqPeopleVaccinated
--, (SubseqPeopleVaccinated/dea.population)*100 as PercentpplVaccinated 
From PortfolioProject_I..['CovidDeaths'] dea
Join PortfolioProject_I..['CovidVaccinations'] vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not NULL
--order by 2,3