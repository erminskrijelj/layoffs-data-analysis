-- Data Cleaning -- 

-- Firstly we should check the data that we will be working with

SELECT * 
FROM world_layoffs.layoffs;

-- Creating staging table and we will work with it and use it for cleaning the data. 
-- We want to have a table with raw data in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- 1. Remove Duplicates
SELECT *
FROM world_layoffs.layoffs_staging;

-- Checking for duplicates 
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    

-- We should remove the rows where is row_num greater than 1. If we want to do that we should add row_num column in our table 
ALTER TABLE world_layoffs.layoffs_staging
ADD row_num int;

DELETE from world_layoffs.layoffs_staging;

-- Checking that our staging table is now empty
SELECT * 
FROM  world_layoffs.layoffs_staging;

-- Filling the staging table with data from layoffs table with raw data and calculated values for row_num column
INSERT INTO `world_layoffs`.`layoffs_staging`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs;
        
SELECT *
FROM world_layoffs.layoffs_staging
WHERE row_num > 1;

-- Finally, now we can delete the duplicates from our stagging table

DELETE FROM world_layoffs.layoffs_staging
WHERE row_num >= 2;


-- 2. Standardize Data

SELECT * 
FROM world_layoffs.layoffs_staging;

-- industry column:
-- If we look at industry it looks like we have some null and empty rows
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging
ORDER BY industry;

SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;


-- We should set the blanks to nulls, after that we only have nulls and that's easier to work with 
UPDATE world_layoffs.layoffs_staging
SET industry = NULL
WHERE industry = '';

-- Checking the rows which value of company column is null
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL 
ORDER BY industry;

-- We should change null value of industry column with proper value if  it exists

UPDATE layoffs_staging t1
JOIN layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Checking for rows with a null value in the industry column one more time. 
-- It looks like Bally's company row was the only one that wasn't changed.
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- I also noticed the Crypto has multiple different variations. 
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging
ORDER BY industry;

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry like 'Crypto%';

-- Now industry column is fixed

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging
ORDER BY industry;
-- --------------------------------------------------
SELECT *
FROM world_layoffs.layoffs_staging;

-- date column:
-- We should use a date instead of a string type for the date column 
UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;


-- country column:
-- Some rows have a '.' character at the end of country name. We should fix it.
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging
ORDER BY country;

UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

SELECT DISTINCT country
FROM world_layoffs.layoffs_staging
ORDER BY country;

SELECT *
FROM world_layoffs.layoffs_staging;

-- ----------------------------------------------------------------------------------------
-- Removing any columns and rows we need to

SELECT *
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging;

ALTER TABLE layoffs_staging
DROP COLUMN row_num;

-- Finally, we have a table with fixed data
SELECT * 
FROM world_layoffs.layoffs_staging;

