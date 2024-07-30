-- Exploratory Data Analysis

-- We will use the table that we earlier prepared
SELECT * 
FROM world_layoffs.layoffs_staging;

-- Max and min percentages of laid off
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging
WHERE  percentage_laid_off IS NOT NULL;

-- percentage_laid_off = 1  ==>  100%
SELECT *
FROM world_layoffs.layoffs_staging
WHERE  percentage_laid_off = 1;

-- Companies with the biggest single Layoff
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging
ORDER BY total_laid_off DESC
LIMIT 5;

-- Stored procedures of Top n companies with the biggest total layoffs
DELIMITER $$
CREATE PROCEDURE the_biggest_n_layoffs (n int)
BEGIN
	SELECT company, SUM(total_laid_off) as `Total laid off per company`
	FROM world_layoffs.layoffs_staging
	GROUP BY company
	ORDER BY `Total laid off per company` DESC
	LIMIT n;
END $$
DELIMITER ;

CALL the_biggest_n_layoffs(5);

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off) AS `Total laid off per company`
FROM world_layoffs.layoffs_staging
GROUP BY company
ORDER BY `Total laid off per company` DESC
LIMIT 10;

-- Layoffs grouped by location 
SELECT location,  SUM(total_laid_off) as `Total laid off per company`
FROM world_layoffs.layoffs_staging
GROUP BY location
ORDER BY `Total laid off per company` DESC
LIMIT 10;

-- Layoffs grouped by country 
SELECT country, SUM(total_laid_off) as `Total laid off per company`
FROM world_layoffs.layoffs_staging
GROUP BY country
ORDER BY `Total laid off per company` DESC;

-- Layoffs grouped by year 
SELECT YEAR(date) as years, SUM(total_laid_off) as `Total laid off per company`
FROM world_layoffs.layoffs_staging
GROUP BY years
ORDER BY `Total laid off per company` ASC;

-- Layoffs grouped by industry
SELECT industry, SUM(total_laid_off) as `Total laid off per company`
FROM world_layoffs.layoffs_staging
GROUP BY industry
ORDER BY `Total laid off per company` DESC;

-- Layoffs grouped by stage
SELECT stage, SUM(total_laid_off) as `Total laid off per company`
FROM world_layoffs.layoffs_staging
GROUP BY stage
ORDER BY `Total laid off per company` DESC;


-- Top 3 layoffs of every single year
WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;



-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
GROUP BY dates
ORDER BY dates ASC;

-- Use a rolling total of layoffs per month as CTE table
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, total_laid_off ,SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;



