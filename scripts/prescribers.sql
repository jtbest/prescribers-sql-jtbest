-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    
SELECT p.npi, SUM(pr.total_claim_count) as total_claims
FROM prescriber as p
INNER JOIN prescription as pr
USING(npi)
GROUP BY p.npi
ORDER BY total_claims DESC;

--	1881634483 with 99707 claims

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT CONCAT(p.nppes_provider_last_org_name, ', ',p.nppes_provider_first_name),specialty_description, 
	SUM(pr.total_claim_count) as total_claims 
FROM prescriber as p
INNER JOIN prescription as pr
	USING(npi)
GROUP BY p.npi,CONCAT(p.nppes_provider_last_org_name, ', ',p.nppes_provider_first_name),specialty_description
ORDER BY total_claims DESC;

--	PENDLEY, BRUCE

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT p.specialty_description, SUM(p1.total_claim_count) as total_claims
FROM prescriber as p
INNER JOIN prescription as p1
	USING(npi)
GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- Family Practice 

--     b. Which specialty had the most total number of claims for opioids?

SELECT p.specialty_description, SUM(p1.total_claim_count) as opioid_claims
FROM prescriber as p
INNER JOIN prescription as p1
	USING(npi)
INNER JOIN drug as d
	USING(drug_name)
WHERE d.opioid_drug_flag='Y'
GROUP BY p.specialty_description
ORDER BY opioid_claims DESC;

-- Nurse Practitioner 

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT 
	p.specialty_description
FROM prescriber as p
LEFT JOIN prescription as p2
	USING (npi)
GROUP BY p.specialty_description
HAVING SUM(total_claim_count) IS NULL
ORDER BY specialty_description;


SELECT DISTINCT(specialty_description)
FROM prescriber
WHERE specialty_description NOT IN
		(SELECT specialty_description
		FROM prescriber
		INNER JOIN prescription
		USING (npi))

-- Yes, 15 of them. 

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH cte AS (SELECT specialty_description,
			 SUM(total_claim_count) as opioid
	  FROM prescriber as p
	  LEFT JOIN prescription as p1
	  	USING (npi)
	  LEFT JOIN drug as d
	 	 USING (drug_name)
	  WHERE d.opioid_drug_flag = 'Y'
	  GROUP BY specialty_description)

SELECT p.specialty_description, 
	COALESCE(cte.opioid,0) as opioid_claims, 
	COALESCE(SUM(p1.total_claim_count),0) as total_claims, 
	CONCAT(ROUND(100*COALESCE(cte.opioid/SUM(p1.total_claim_count),0),2),' %') 
		as opioid_pct
FROM prescriber as p
LEFT JOIN prescription as p1
	USING (npi)
LEFT JOIN cte
	USING (specialty_description)
GROUP BY p.specialty_description, cte.opioid
ORDER BY COALESCE(cte.opioid/SUM(p1.total_claim_count),0)DESC, 
		total_claims DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT d.generic_name, CONCAT('$ ',ROUND(p.total_drug_cost,2))
FROM drug as d
INNER JOIN prescription as p
	USING(drug_name)
ORDER BY total_drug_cost DESC;

-- PIRFENIDONE

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT d.generic_name, 
	CONCAT('$ ',ROUND(p.total_drug_cost,2)),
	CONCAT('$ ', ROUND((p.total_drug_cost/p.total_day_supply),2)) 
	as cost_per_day
FROM drug as d
INNER JOIN prescription as p
	USING(drug_name)
ORDER BY (total_drug_cost/total_day_supply) DESC;

--	IMMUN GLOB(IGG)/GLY/IGA OVA50 at $7141.11 per day

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_type

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE WHEN opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type,
		MONEY(ROUND(SUM(p.total_drug_cost),2)) as total_cost
FROM drug as d 
INNER JOIN prescription as p
	USING(drug_name)
WHERE opioid_drug_flag = 'Y' OR antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY SUM(p.total_drug_cost) DESC;

-- More spent on opioids. 

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT f.state, count(c.cbsa) as cbsa_count
FROM fips_county as f
INNER JOIN cbsa as c
	USING (fipscounty)
WHERE state = 'TN'
GROUP BY f.state;

-- 42

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT c.cbsaname, SUM(p.population) as total_pop
FROM cbsa as c
LEFT JOIN fips_county as f
	USING(fipscounty)
LEFT JOIN population as p
	USING (fipscounty)
GROUP BY c.cbsaname
HAVING SUM(p.population) IS NOT NULL
ORDER BY total_pop DESC;


-- Largest is Nashville-Davidson-Murfreesboro-Franklin, TN

SELECT 
	c.cbsaname, 
	SUM(p.population) as total_pop
FROM cbsa as c
LEFT JOIN fips_county as f
	USING(fipscounty)
LEFT JOIN population as p
	USING (fipscounty)
GROUP BY c.cbsaname
ORDER BY total_pop;

-- Smallest is Morristown, TN

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT 
	CONCAT(f.county, ', ', f.state),
	p.population
FROM population as p
LEFT JOIN fips_county as f
	USING(fipscounty)
LEFT JOIN cbsa as c
	USING(fipscounty)
WHERE c.fipscounty IS NULL
ORDER BY p.population DESC
LIMIT 1;

--	SEVIER, TN: 95523

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT p.drug_name, p.total_claim_count
FROM prescription as p
WHERE total_claim_count >= 3000

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	p.drug_name, 
	p.total_claim_count, 
	d.opioid_drug_flag
FROM prescription as p
LEFT JOIN drug as d
USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY p.total_claim_count DESC;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	p.drug_name, 
	p.total_claim_count, 
	d.opioid_drug_flag,
CONCAT(pr.nppes_provider_first_name, ' ', pr.nppes_provider_last_org_name)
FROM prescription as p
LEFT JOIN drug as d
	USING (drug_name)
LEFT JOIN prescriber as pr
	ON p.npi=pr.npi
WHERE total_claim_count >= 3000
ORDER BY p.total_claim_count DESC;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT p1.npi, 
	d.drug_name
FROM prescriber as p1
CROSS JOIN drug as d
WHERE p1.specialty_description = 'Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
ORDER BY p1.npi;

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).


SELECT p1.npi, 
	d.drug_name,
	(SELECT p2.total_claim_count
		FROM prescription as p2
		WHERE p1.npi=p2.npi
		AND p2.drug_name=d.drug_name) as total_count
FROM prescriber as p1
CROSS JOIN drug as d
WHERE p1.specialty_description = 'Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
ORDER BY p1.npi;

-- This works but takes an absolutely bonkers amount of time to run
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


SELECT p1.npi, 
	d.drug_name,
	COALESCE(
		(SELECT p2.total_claim_count
		FROM prescription as p2
		WHERE p1.npi=p2.npi
		AND p2.drug_name=d.drug_name),0) as total_count
FROM prescriber as p1
CROSS JOIN drug as d
WHERE p1.specialty_description = 'Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
ORDER BY total_count DESC;

-- Over 1 min to run. Figure out how to use join rather than subquery

SELECT p1.npi, 
	d.drug_name,
	COALESCE(p2.total_claim_count,0) as total_count
FROM prescriber as p1
CROSS JOIN drug as d
LEFT JOIN prescription as p2
	ON d.drug_name = p2.drug_name 
	AND p2.npi=p1.npi
WHERE p1.specialty_description = 'Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
ORDER BY total_count DESC;

-- Much better 

-- BONUS --
-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT
(SELECT COUNT(DISTINCT npi)
FROM prescriber)-
(SELECT COUNT(DISTINCT npi)
FROM prescription)

--	4458
-- Look for another way to do this based on filters

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) as total_claims
FROM (SELECT npi
	 FROM prescriber
	 WHERE specialty_description = 'Family Practice') as sub
INNER JOIN prescription as p
	USING(npi)
INNER JOIN drug as d
	USING (drug_name)
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;


--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) as total_claims
FROM (SELECT npi
	 FROM prescriber
	 WHERE specialty_description = 'Cardiology') as sub
INNER JOIN prescription as p
	USING(npi)
INNER JOIN drug as d
	USING (drug_name)
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.


SELECT generic_name, SUM(total_claim_count) as total_claims
FROM (SELECT npi
	 FROM prescriber
	 WHERE specialty_description = 'Family Practice' OR specialty_description = 'Cardiology') as sub
INNER JOIN prescription as p
	USING(npi)
INNER JOIN drug as d
	USING (drug_name)
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;


-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    
SELECT npi, SUM(total_claim_count)as total_claims, nppes_provider_city as city
FROM (SELECT npi, nppes_provider_city
	 FROM prescriber
	 WHERE nppes_provider_city ='NASHVILLE') as sub
INNER JOIN prescription as p
	USING (npi)
GROUP BY npi, city
ORDER BY total_claims DESC
LIMIT 5;
	
-- Think about why city has to be included in GROUP BY	

--     b. Now, report the same for Memphis.

SELECT npi, SUM(total_claim_count)as total_claims, nppes_provider_city as city
FROM (SELECT npi, nppes_provider_city
	 FROM prescriber
	 WHERE nppes_provider_city ='MEMPHIS') as sub
INNER JOIN prescription as p
	USING (npi)
GROUP BY npi, city
ORDER BY total_claims DESC
LIMIT 5;
	
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT npi, SUM(total_claim_count)as total_claims, nppes_provider_city as city
FROM (SELECT npi, nppes_provider_city
	 FROM prescriber
	 WHERE nppes_provider_city IN('NASHVILLE','MEMPHIS','KNOXVILLE','CHATTANOOGA')) as sub
INNER JOIN prescription as p
	USING (npi)
GROUP BY npi, city
ORDER BY total_claims DESC
LIMIT 5;


-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT county, deaths
FROM overdoses
INNER JOIN fips_county
	USING(fipscounty)
WHERE deaths > (SELECT AVG(deaths)
				FROM overdoses)
ORDER BY deaths DESC;

-- 5.
--     a. Write a query that finds the total population of Tennessee.

SELECT SUM(population)
FROM population
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN'
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county, population, 
		CONCAT(ROUND(100*(population)/(SELECT SUM(population)
		FROM population
		INNER JOIN fips_county
		USING(fipscounty)
		WHERE state = 'TN'),2),' %') as pct_tn
FROM population
INNER JOIN fips_county
	USING(fipscounty)
WHERE state ='TN'
ORDER BY population DESC;
