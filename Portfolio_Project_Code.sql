Select*
From Portfolio_Project..CovidDeaths
order by 3,4

Select*
From Portfolio_Project..CovidVaccinations
order by 3,4

--Select the Data we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From Portfolio_Project..CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows Liklihood of dying if you contract covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio_Project..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From Portfolio_Project..CovidDeaths
where location like '%states%'
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population

Select location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From Portfolio_Project..CovidDeaths
--where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--Showing countries with highest death count per Population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_Project..CovidDeaths
--where location like '%states%'
where continent is not null
Group by Location
order by TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population

---Two Methods to break things down  which is continent is null

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_Project..CovidDeaths
--where location like '%states%'
where continent is null
Group by location
order by TotalDeathCount desc

-- OR Continent is NOT Null
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_Project..CovidDeaths
--where location like '%states%'
where continent is not null
Group by continent
order by TotalDeathCount desc

--Showing continents with the highest death count per population


--GLOBAL NUMBERS
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From Portfolio_Project..CovidDeaths
-- where location like '%states%'
where continent is not null
Group by date
order by 1,2


--IF you remove the date, you get the death percentage across the total world
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From Portfolio_Project..CovidDeaths
-- where location like '%states%'
where continent is not null
--Group by date
order by 1,2

--JOINING TABLES  Covid Deaths and Covid Vaccinations
Select * 
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- Looking at Total Population vs Vaccinations
-- What are the total number of people in the world that have been vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

--- PARTITIONS     Calculate rolling count of new vaccinations per day partitioned by Continent to restart count at new continent
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) 
OVER (Partition by dea.Location Order by dea.location, dea.date) as CumulativeVaccinations
--, (CumulativeVaccinations/population)*100
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as CumulativeVaccinations
--, (CumulativeVaccinations/population)*100
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (CumulativeVaccinations/Population)*100
From PopvsVac


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
-- Specific our columns
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVaccinations numeric
)
-- Inserting the data
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as CumulativeVaccinations
--, (CumulativeVaccinations/population)*100
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null
-- order by 2,3
-- Actually Select it
Select *, (CumulativeVaccinations/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as CumulativeVaccinations
--, (CumulativeVaccinations/population)*100
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3


--Now that the View has been created and saved you can write queries off of that
Select *
From PercentPopulationVaccinated
--- It is not a temp table  it is now permanent 
--- Can be used for visualizations