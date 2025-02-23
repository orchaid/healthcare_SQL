Select * FROM hospital_data.hospital_beds

Select 
    provider_ccn,
    count(provider_ccn) as num_of_repetition
FROM hospital_data.hospital_beds
GROUP BY provider_ccn
ORDER BY num_of_repetition DESC


/* What needs to be cleaned:
    - The provider_ccn column is supposed to have 6 digits but excel removes the leading 0 so I will fix it.
    - The dates columns are in a wrong formula that tableau wouldn't recognize so I should correct the format.
    - One hospital with the same ccn can give 2 reporting of the number of beds for various reasons, so I have to choose from the most recent.
*/


with beds as 
(
Select 
    LPAD(CAST(provider_ccn AS text), 6 , '0') AS provider_ccn,
    to_date(fiscal_year_begin_date, 'MM-DD-YYYY') AS fiscal_year_begin_date,
    to_date(fiscal_year_end_date, 'MM-DD-YYYY') AS fiscal_year_end_date,
    number_of_beds,
    ROW_NUMBER() over( partition by provider_ccn  ORDER BY to_date(fiscal_year_end_date, 'MM-DD-YYYY') DESC) AS row_num-- ordering it by the end date so that 1 is for the most decent and 2 or above for what's before chronoligically
FROM hospital_data.hospital_beds
)
Select 
    LPAD(CAST(facility_id AS text), 6 , '0') AS provider_ccn 
    , *
FROM hospital_data.hcahps_data AS hcahps
LEFT JOIN beds 
    ON LPAD(CAST(facility_id AS text), 6 , '0') = beds.provider_ccn
    and row_num = 1



