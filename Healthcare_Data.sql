SELECT * 
FROM healthcare.encounters
where encounterclass in ('outpatient', 'ambulatory') -- looking for one thing or another in one column
    /*and description = 'ICU Admission'
    and stop BETWEEN '2023-1-1 00:00' and '2023-12-30 23:59';
*/


-------- count of description while excluding overweight and ordering it descendingly and filtering above 5000 
SELECT 
    description,
    count(description) as count_of_con
FROM healthcare.conditions
WHERE description != 'Body Mass Index 30.0-30.9, adult'
GROUP BY description 
HAVING count(description) >= 5000
order BY count_of_con DESC


SELECT *
FROM healthcare.patients
WHERE city = 'Boston'



-------- Choronic kidney disease

SELECT * 
From healthcare.conditions
WHERE code in ('585.1', '585.2', '585.3', '585.4')



-------- The count of patients in each city where the city is not Boston and the number of patients is greater than 100
SELECT 
    city,
    count(*) AS num_of_patients
FROM healthcare.patients
WHERE city != 'Boston'
GROUP BY city
HAVING count(*) >= 100 
ORDER BY num_of_patients DESC


--------------------------------------------------------------------------------
/* Manipulating data and extracting it using SQL then visualizing with tableau

Coming up with flu shots dashboard for 2022 that does the follwing

1) Total percentage of patients getting flu shots stratified by:
    - age
    - race
    - county (on a map)
    - overall

2) Running total of flu shots over the course of 2022

3) Total number of flu shots given in 2022

4) A list of patients that show whether or not they recieved flu shots

Requirements:
    patients must have been "Active in our hospital"
*/
-------just exploring
--age
SELECT extract(year from age('2022-1-1', birthdate)) as age, birthdate
FROM healthcare.patients
WHERE deathdate is NULL

--Race
SELECT race,
    count(*)
FROM healthcare.patients
GROUP BY race

--county
SELECT county,
    count(*)
FROM healthcare.patients
GROUP BY county
-------------- now 

SELECT 
    pat.birthdate,
    pat.race,
    pat.county,
    pat.id,
    pat.first,
    pat.last
From healthcare.patients as pat


-- I want the patients who recieved the seasonal flu vaccine 
SELECT imu.patient, min(imu.date) AS earliest_flu_shot_2022 -- to prevent repetition in the data
From healthcare.immunizations AS imu
WHERE description = 'Seasonal Flu Vaccine'
    AND date BETWEEN '2022-1-1 00:00' and '2022-12-30 23:59'
Group BY patient

-- this patient took 2 flu shots in 2022
SELECT * 
FROM healthcare.immunizations
WHERE patient = 'fff4ca84-efd5-88ab-d713-aa54d26cea91'



-- To satisfy the requirment that the patient should be active to the hospital, I filtered based on the encounter table for the year 2022 and that they are not dead and also not children tat take a flu shot every 6 months
SELECT patient , count(patient)
FROM healthcare.encounters as enc
JOIN healthcare.patients AS pat
    ON pat.id = enc.patient
    AND enc.start BETWEEN '2022-1-1 00:00' and '2022-12-30 23:59'
    AND pat.deathdate IS NULL
    AND EXTRACT( MONTH from age('2022-12-31', pat.birthdate)) >= 6
GROUP BY patient    -- There is repetition





/* Manipulating data and extracting it using SQL then visualizing with tableau

Coming up with flu shots dashboard for 2022 that does the follwing

1) Total percentage of patients getting flu shots stratified by:
    - age
    - race
    - county (on a map)
    - overall

2) Running total of flu shots over the course of 2022

3) Total number of flu shots given in 2022

4) A list of patients that show whether or not they recieved flu shots

Requirements:
    patients must have been "Active in our hospital"
*/


WITH active_patients as
(
SELECT patient 
FROM healthcare.encounters as enc
JOIN healthcare.patients AS pat
    ON pat.id = enc.patient
    AND enc.start BETWEEN '2020-1-1 00:00' and '2022-12-30 23:59'
    AND pat.deathdate IS NULL
    AND EXTRACT( MONTH from age('2022-12-31', pat.birthdate)) >= 6
),

flu_shot_2022 as
(
SELECT imu.patient, min(imu.date) AS earliest_flu_shot_2022
From healthcare.immunizations AS imu
WHERE description = 'Seasonal Flu Vaccine'
    AND date BETWEEN '2022-1-1 00:00' and '2022-12-30 23:59'
Group BY patient
)
SELECT 
    EXTRACT(YEAR FROM AGE('2022-12-31',pat.birthdate)) AS age,
    pat.race,
    pat.ethnicity,
    pat.county,
    pat.id,
    pat.gender,
    pat.first,
    pat.last,
    flu.earliest_flu_shot_2022-- will help in calculating the percentage of who took the shot from who didn't later on
    ,CASE when flu.patient is NULL THEN 0 else 1 
    END AS flu_shot_2022,
    pat.zip
From healthcare.patients as pat
Left Join flu_shot_2022 as flu
    ON pat.id = flu.patient

Where pat.id IN (SELECT patient FROM active_patients ) -- didn't need to write DISTINCT in active_patients, as It acts as a filter to include only those pat.id values that exist in active_patients, ensuring that each pat.id appears only once.
/*Why?
The IN clause checks for existence in active_patients but does not create duplicates.
If pat.id is unique in the patients table, then IN will only keep those unique values that match.
Even if active_patients contains duplicate patient values, it won’t affect the final result because IN only tests for membership, not multiplicity.*/