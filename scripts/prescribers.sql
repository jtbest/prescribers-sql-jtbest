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
ORDER BY total_claims DESC;

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
	p.specialty_description, 
	SUM(total_claim_count) as all_claims
FROM prescriber as p
LEFT JOIN prescriber as p1
	USING (npi)
LEFT JOIN prescription as p2
	USING (npi)
GROUP BY p.specialty_description
HAVING SUM(total_claim_count) IS NULL
ORDER BY specialty_description;

-- Yes, 15 of them. 

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?


WITH cte as (SELECT p.specialty_description, p2.npi, p2.total_claim_count, d.opioid_drug_flag
			FROM prescription as p2
			LEFT JOIN drug as p1
			USING(npi)
			LEFT JOIN prescription as p2
			ON p.npi =p2.npi AND p2.drug_name=d.drug_name
			LEFT JOIN drug as d
			USING (drug_name)
			WHERE opioid_drug_flag = 'Y')

SELECT p.specialty_description,
	SUM(p1.total_claim_count) as total_claims,
	SUM(cte.total_claim_count) as opioid_claims,
	(SUM(cte.total_claim_count)/SUM(p1.total_claim_count)) as opioid_pct
FROM prescriber as p
LEFT JOIN prescription as p1
	USING(npi)
LEFT JOIN cte
USING(npi)
GROUP BY p.specialty_description
ORDER BY p.specialty_description DESC;



WITH cte as (SELECT p.specialty_description, p2.npi, p2.total_claim_count, d.opioid_drug_flag
			FROM prescriber as p
			JOIN prescriber as p1
			USING(npi)
			LEFT JOIN prescription as p2
			ON p.npi =p2.npi AND p2.drug_name=d.drug_name
			LEFT JOIN drug as d
			USING (drug_name)
			WHERE opioid_drug_flag = 'Y')


SELECT p.specialty_description, 
SUM(p1.total_claim_count) as total_claims,
(SELECT SUM(total_claim_count)
	FROM 
 		(SELECT npi,total_claim_count, opioid_drug_flag
		FROM prescriber as p
		LEFT JOIN prescriber as p1
			USING(npi)
		LEFT JOIN prescription as p2
			USING (npi)
		LEFT JOIN drug as d
			USING (drug_name)
		WHERE p2.npi=p.npi)as subq
	WHERE opioid_drug_flag = 'Y') as opioid_total		
FROM prescriber as p
INNER JOIN prescription as p1
	USING(npi)
INNER JOIN drug as d
	USING(drug_name)
GROUP BY p.specialty_description
ORDER BY p.specialty_description DESC;

-- cte to get total opioid by specialty. try a case statement too 

SELECT npi,total_claim_count, opioid_drug_flag
FROM prescriber as p
LEFT JOIN prescriber as p1
USING(npi)
LEFT JOIN prescription as p2
USING (npi)
LEFT JOIN drug as d
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT d.generic_name, CONCAT('$ ',ROUND(p.total_drug_cost,2))
FROM drug as d
INNER JOIN prescription as p
USING(drug_name)
ORDER BY total_drug_cost DESC;

-- PIRFENIDONE

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT d.generic_name, CONCAT('$ ',ROUND(p.total_drug_cost,2)),CONCAT('$ ', ROUND((p.total_drug_cost/p.total_day_supply),2)) as cost_per_day
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
	CONCAT('$ ', ROUND(SUM(p.total_drug_cost),2)) as total_cost
FROM drug as d 
INNER JOIN prescription as p
USING(drug_name)
GROUP BY drug_type
ORDER BY SUM(p.total_drug_cost) DESC;

SELECT 
	CASE WHEN opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type,
		MONEY(ROUND(SUM(p.total_drug_cost),2)) as total_cost
FROM drug as d 
INNER JOIN prescription as p
	USING(drug_name)
GROUP BY drug_type
ORDER BY SUM(p.total_drug_cost) DESC;

-- More spent on opioids. Go back and figure out how to eliminate 'neither'

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT f.state, count(c.cbsa)
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
LEFT JOIN cbsa as c
	USING(fipscounty)
LEFT JOIN fips_county as f
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
ON d.drug_name = p2.drug_name AND p2.npi=p1.npi
WHERE p1.specialty_description = 'Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'
ORDER BY total_count DESC;

-- Much better 


