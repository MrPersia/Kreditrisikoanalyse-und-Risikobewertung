CREATE DATABASE IF NOT EXISTS credit_risk_project;
USE credit_risk_project;

SELECT * FROM credit_risk_dataset;

SHOW VARIABLES LIKE "secure_file_priv";
CREATE TABLE IF NOT EXISTS credit_risk_dataset (
    person_age INT,
    person_income INT,
    person_home_ownership VARCHAR(255),
    person_emp_length DECIMAL(10, 2),
    loan_intent VARCHAR(255),
    loan_grade VARCHAR(255),
    loan_amnt INT,
    loan_int_rate DECIMAL(5, 2),
    loan_status BOOLEAN,
    loan_percent_income DECIMAL(5, 2),
    cb_person_default_on_file VARCHAR(50),
    cb_person_cred_hist_length INT
);

SET GLOBAL local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_risk_dataset.csv'
INTO TABLE credit_risk_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(person_age,
 person_income,
 person_home_ownership,
 @person_emp_length,
 loan_intent,
 loan_grade,
 loan_amnt,
 @loan_int_rate,
 @loan_status,
 @loan_percent_income,
 cb_person_default_on_file,
 cb_person_cred_hist_length
)
SET
 person_emp_length = NULLIF(@person_emp_length, ''),
 loan_int_rate = NULLIF(@loan_int_rate, ''),
 loan_status = NULLIF(@loan_status, ''),
 loan_percent_income = NULLIF(@loan_percent_income, '');


-- Zeige alle infos der Tabelle "credit_risk_dataset"
DESC credit_risk_dataset;
SHOW COLUMNS FROM credit_risk_dataset;
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'credit_risk_dataset';

-- **person_age (Age):** Alter
-- **person_income (Annual Income):** Jährliches Einkommen
-- **person_home_ownership (Home ownership):** Wohnsitzstatus
-- **person_emp_length (Employment length):** Beschäftigungsdauer
-- **loan_intent (Loan intent):** Kreditzweck
-- **loan_grade (Loan grade):** Kreditnote
-- **loan_amnt (Loan amount):** Kreditbetrag
-- **loan_int_rate (Interest rate):** Zinssatz
-- **loan_status (Loan status):** Kreditstatus (0: kein Ausfall, 1: Ausfall)
-- **loan_percent_income (Percent income):** Prozentuales Einkommen
-- **cb_person_default_on_file (Historical default):** Historischer Zahlungsausfall
-- **cb_person_cred_hist_length (Credit history length):** Kredithistorienlänge

SELECT * FROM credit_risk_dataset;


-- Sucht nach Nullwerten in allen Spalten der Tabelle
SELECT *
FROM credit_risk_dataset
WHERE
    person_age IS NULL OR
    person_income IS NULL OR
    person_home_ownership IS NULL OR
    person_emp_length IS NULL OR
    loan_intent IS NULL OR
    loan_grade IS NULL OR
    loan_amnt IS NULL OR
    loan_int_rate IS NULL OR
    loan_status IS NULL OR
    loan_percent_income IS NULL OR
    cb_person_default_on_file IS NULL OR
    cb_person_cred_hist_length IS NULL;

SELECT *
FROM credit_risk_dataset
WHERE
    person_emp_length IS NULL OR
    loan_int_rate IS NULL;

-- Anzahl der Nullwerte in den Spalten person_emp_length und loan_int_rate
SELECT
    COUNT(CASE WHEN person_emp_length IS NULL THEN 1 END) AS null_count_person_emp_length,
    COUNT(CASE WHEN loan_int_rate IS NULL THEN 1 END) AS null_count_loan_int_rate
FROM credit_risk_dataset;




-- Analyse der Kreditüberwachung

SELECT 
    loan_status,
    COUNT(*) AS num_loans,
	CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2), '%') AS num_loans_percentage,
    ROUND(AVG(person_age), 2) AS avg_age,
    ROUND(AVG(person_income), 2) AS avg_income,
    ROUND(MAX(person_income), 2) AS max_income,
    ROUND(MIN(person_income), 2) AS min_income,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amnt,
    ROUND(MAX(loan_amnt), 2) AS max_loan_amnt,
    ROUND(MIN(loan_amnt), 2) AS min_loan_amnt,
    ROUND(AVG(loan_int_rate), 2) AS avg_int_rate,
    ROUND(MAX(loan_int_rate), 2) AS max_int_rate,
    ROUND(MIN(loan_int_rate), 2) AS min_int_rate
FROM credit_risk_dataset
GROUP BY loan_status
ORDER BY num_loans DESC;

-- Mittelwert von Einkommen und Kreditbetrag beeinflussen die Situation.

-- Analyse der Kreditvergabe nach Altersgruppen und Kreditzustand
SELECT 
    CASE 
        WHEN person_age < 30 THEN 'Under 30'
        WHEN person_age >= 30 AND person_age < 40 THEN '30-39'
        WHEN person_age >= 40 AND person_age < 50 THEN '40-49'
        WHEN person_age >= 50 THEN '50 and above'
    END AS age_group,
    loan_status,
    COUNT(*) AS num_loans,
    ROUND(AVG(person_income)) AS avg_income,
    ROUND(AVG(loan_amnt)) AS avg_loan_amnt,
    ROUND(AVG(loan_int_rate), 2) AS avg_int_rate
FROM credit_risk_dataset
GROUP BY age_group, loan_status
ORDER BY loan_status DESC;

SELECT 
    CASE 
        WHEN person_age < 30 THEN 'Under 30'
        WHEN person_age >= 30 AND person_age < 40 THEN '30-39'
        WHEN person_age >= 40 AND person_age < 50 THEN '40-49'
        WHEN person_age >= 50 THEN '50 and above'
    END AS age_group,
    loan_status,
    COUNT(*) AS num_loans,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY
        CASE 
            WHEN person_age < 30 THEN 'Under 30'
            WHEN person_age >= 30 AND person_age < 40 THEN '30-39'
            WHEN person_age >= 40 AND person_age < 50 THEN '40-49'
            WHEN person_age >= 50 THEN '50 and above'
        END
    ), 2), "%") AS loan_percentage
FROM credit_risk_dataset
GROUP BY age_group, loan_status
ORDER BY loan_status DESC, num_loans DESC;

-- Kredite konzentrieren sich auf Personen < 30 Jahre.
-- Am wenigsten Risiko bei Personen im Alter von 30 bis 50.
-- Altersgruppe über 50 in Krediten vertreten (25% nicht zurückgezahlt).



-- Personen-Einkommen x1000 im Verhältnis zum Kreditstatus
SELECT 
    income_range,
    loan_status,
    COUNT(*) AS count,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY income_range), 2), '%') AS percentage
FROM (
    SELECT 
        loan_status,
        CASE 
            WHEN person_income / 1000 <= 10 THEN '0-10K'
            WHEN person_income / 1000 > 10 AND person_income / 1000 <= 20 THEN '10-20K'
            WHEN person_income / 1000 > 20 AND person_income / 1000 <= 30 THEN '20-30K'
            WHEN person_income / 1000 > 30 AND person_income / 1000 <= 40 THEN '30-40K'
            WHEN person_income / 1000 > 40 AND person_income / 1000 <= 50 THEN '40-50K'
            WHEN person_income / 1000 > 50 THEN '50K and above'
        END AS income_range
    FROM credit_risk_dataset
) AS subquery
GROUP BY income_range, loan_status 
ORDER BY loan_status DESC, count DESC;

-- Niedrigeres Einkommen, höheres Kreditausfallrisiko (Tabelle).
-- Ca. 75-85% mit Einkommen unter 20.000 haben nicht zurückgezahlt.
-- Einkommen beeinflusst Rückzahlungswahrscheinlichkeit.


-- Persönliche Wohneigentumsanalyse
SELECT 
    person_home_ownership,
    loan_status,
    COUNT(*) AS num_records,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER 
    (PARTITION BY person_home_ownership), 2), '%') AS percentage
FROM credit_risk_dataset 
GROUP BY person_home_ownership, loan_status 
ORDER BY loan_status DESC, num_records DESC;


-- Mietzahlung erschwert Kreditrückzahlung.
-- 31% der Mietzahler zahlen nicht zurück, zeigen höheres Kreditrisiko.
-- Miete ≠ Kredit (unterschiedliche Rückzahlungsverläufe).



-- Analyse der Kreditstatus-Verteilung nach Beschäftigungsdauer
SELECT 
    emp_length_group,
    loan_status,
    COUNT(*) AS num_records,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY emp_length_group), 2), '%') AS percentage
FROM (
    SELECT 
        CASE
            WHEN person_emp_length = 0 THEN '0'
            WHEN person_emp_length > 0 AND person_emp_length < 5 THEN '1-5'
            WHEN person_emp_length >= 5 AND person_emp_length < 10 THEN '5-9'
            WHEN person_emp_length >= 10 AND person_emp_length < 20 THEN '10-19'
            WHEN person_emp_length >= 20 AND person_emp_length < 30 THEN '20-29'
            WHEN person_emp_length >= 30 THEN '30 and above'
        END AS emp_length_group,
        loan_status
    FROM credit_risk_dataset
    WHERE person_emp_length IS NOT NULL
) AS subquery
GROUP BY emp_length_group, loan_status
ORDER BY loan_status DESC, num_records DESC;

-- Beschäftigungsdauer 5-20: Mehr Rückzahlung, weniger Risiko.
-- Beschäftigungsdauer unter 5 und über 20: Weniger Rückzahlung, mehr Risiko.


-- Analyse der Kreditabsicht
SELECT 
    loan_intent,
    loan_status,
    COUNT(*) AS num_records,
	CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER 
    (PARTITION BY loan_intent), 2), '%') AS percentage
FROM credit_risk_dataset 
GROUP BY loan_intent, loan_status
ORDER BY loan_status DESC, num_records DESC;

-- Venture-Rückzahlung höher, geringeres Rückzahlungsrisiko für Kredit.
-- Reihenfolge: Debt Consolidation, Medical, Home Improvement. Ca. 26-28% haben keine Rückzahlung und höheres Risiko.

-- Analyse der Kreditnote in Bezug auf Kreditstatus und historische Ausfälle
SELECT 
    loan_grade,
    cb_person_default_on_file,
    loan_status,
    COUNT(*) AS num_records,
	CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER 
    (PARTITION BY loan_grade), 2), '%') AS percentage
FROM credit_risk_dataset 
GROUP BY loan_grade, cb_person_default_on_file, loan_status
ORDER BY loan_grade;

-- Ohne Vergangenheitsausfälle: Geringster Zinssatz in A und B.
-- Höhere Rückzahlungen in diesen Klassen, geringeres Risiko; andere Klassen sind risikoreicher.

-- Analyse der Kreditstatus-loan_amnt
SELECT 
    loan_amnt_group,
    loan_status,
    COUNT(*) AS num_records,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER 
    (PARTITION BY loan_amnt_group), 2), '%') AS percentage
FROM (
    SELECT 
        CASE
            WHEN loan_amnt > 0 AND loan_amnt < 5000 THEN '500-5K'
            WHEN loan_amnt >= 5000 AND loan_amnt < 15000 THEN '5K-15K'
            WHEN loan_amnt >= 15000 AND loan_amnt < 25000 THEN '15K-25K'
            WHEN loan_amnt >= 25000 AND loan_amnt < 35000 THEN '25k-35k'
        END AS loan_amnt_group,
        loan_status
    FROM credit_risk_dataset
    WHERE loan_amnt IS NOT NULL
) AS subquery
GROUP BY loan_amnt_group, loan_status
ORDER BY loan_amnt_group DESC;



-- Analyse des Kreditzinssatzes im Kreditstatus

SELECT 
    CASE
            WHEN loan_int_rate < 5 THEN 'Under 5'
            WHEN loan_int_rate >= 5 AND loan_int_rate <= 10 THEN '5-10'
            WHEN loan_int_rate > 10 AND loan_int_rate <= 15 THEN '11-15'
            WHEN loan_int_rate > 15 AND loan_int_rate <= 20 THEN '16-20'
            WHEN loan_int_rate > 20 THEN 'Over 20'
        END AS int_rate_interval,
    loan_status,
    COUNT(*) AS num_loans,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY
            CASE
                WHEN loan_int_rate < 5 THEN 'Under 5'
                WHEN loan_int_rate >= 5 AND loan_int_rate <= 10 THEN '5-10'
                WHEN loan_int_rate > 10 AND loan_int_rate <= 15 THEN '11-15'
                WHEN loan_int_rate > 15 AND loan_int_rate <= 20 THEN '16-20'
                WHEN loan_int_rate > 20 THEN 'Over 20'
            END
    ), 2), "%") AS loan_percentage
FROM credit_risk_dataset
GROUP BY int_rate_interval, loan_status
ORDER BY  int_rate_interval DESC;

-- Zinssatz über 16% = 60-85% Risiko der Nicht-Rückzahlung.
-- Zinssatz < 16% fördert höhere Rückzahlung.


-- Analyse des cb_person_cred_hist_length im Kreditstatus.
SELECT 
    CASE
            WHEN cb_person_cred_hist_length < 5 THEN 'Under 5'
            WHEN cb_person_cred_hist_length >= 5 AND loan_int_rate <= 10 THEN '5-10'
            WHEN cb_person_cred_hist_length > 10 AND loan_int_rate <= 20 THEN '11-20'
            WHEN cb_person_cred_hist_length > 20 AND loan_int_rate <= 30 THEN '20-30'
            WHEN cb_person_cred_hist_length > 30 THEN 'Over 30'
        END AS cb_person_cred_hist_length,
    loan_status,
    COUNT(*) AS num_loans,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY
            CASE
                WHEN cb_person_cred_hist_length < 5 THEN 'Under 5'
            WHEN cb_person_cred_hist_length >= 5 AND loan_int_rate <= 10 THEN '5-10'
            WHEN cb_person_cred_hist_length > 10 AND loan_int_rate <= 20 THEN '11-20'
            WHEN cb_person_cred_hist_length > 20 AND loan_int_rate <= 30 THEN '20-30'
            WHEN cb_person_cred_hist_length > 30 THEN 'Over 30'
            END
    ), 2), "%") AS loan_percentage
FROM credit_risk_dataset
GROUP BY 1, loan_status
ORDER BY cb_person_cred_hist_length DESC;

-- Größere Menge an Nullwerten, Analyse nicht möglich.






-- Analyse des Verhältnisses von Kreditbetrag zum Einkommen basierend auf dem Kreditzustand
SELECT 
    loan_status,
    ROUND(AVG(loan_amnt / person_income), 2) AS avg_loan_income_ratio, -- Durchschnittsverhältnis von Kreditbetrag zum Einkommen.
    CONCAT(ROUND(AVG(loan_amnt / person_income) * 100, 2), '%') AS "avg_loan_income_ratio_%" --  Prozentuales Durchschnittsverhältnis von Kreditbetrag zum Einkommen.
FROM credit_risk_dataset
GROUP BY loan_status;

-- Höheres prozentuales Durchschnittsverhältnis über 15% belastet die Person stärker.
-- Erhöhte Belastung bedeutet höheres Risiko für Kreditstatus. Fazit: Mehr Belastung, höheres Risiko.


-- Analyse der Verteilung der Kreditzinsen basierend auf dem Kreditzustand und Kreditwürdigkeit
SELECT 
    loan_status,
    cb_person_default_on_file,
    ROUND(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(loan_int_rate ORDER BY loan_int_rate), ',', 0.25 * COUNT(*) + 1), ',', -1), 2) AS q1_int_rate,
    ROUND(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(loan_int_rate ORDER BY loan_int_rate), ',', 0.5 * COUNT(*) + 1), ',', -1), 2) AS median_int_rate,
    ROUND(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(loan_int_rate ORDER BY loan_int_rate), ',', 0.75 * COUNT(*) + 1), ',', -1), 2) AS q3_int_rate
FROM credit_risk_dataset
GROUP BY loan_status, cb_person_default_on_file;

-- Gleichheit bei Quartilen deutet auf Normalverteilung oder symmetrische Struktur hin.





-- Korrelation zwischen Income und Loan Status 
SELECT 
    (AVG(person_income * loan_status) - AVG(person_income) * AVG(loan_status)) /
    (STDDEV(person_income) * STDDEV(loan_status)) AS 'correlation_income_loan_status'
FROM 
    credit_risk_dataset;--
    
-- **Negative Korrelation (-0.14):** Starke negative Beziehung: Einkommen vs. Kreditstatus.
-- **Höhere Einkommen:** Geringeres Kreditausfallrisiko (Loan Status 0).    
    


-- Korrelation zwischen dem Anteil des Einkommens, der für den Kredit aufgewendet wird, und dem Kreditstatus
SELECT 
    (COUNT(*) * SUM(loan_percent_income * loan_status) - SUM(loan_percent_income) * SUM(loan_status)) / 
    SQRT((COUNT(*) * SUM(loan_percent_income * loan_percent_income) - SUM(loan_percent_income) * SUM(loan_percent_income)) * 
    (COUNT(*) * SUM(loan_status * loan_status) - SUM(loan_status) * SUM(loan_status))) AS corr_percent_income_loan_status
FROM 
    credit_risk_dataset; --

-- Positive Korrelation (0.38): Starke positive Beziehung zwischen prozentualem Einkommen und Kreditstatus.
-- Höhere prozentuale Einkommen: Verbunden mit positivem Kreditstatus (kein Ausfall).


SELECT 
    (AVG(person_age * loan_status) - AVG(person_age) * AVG(loan_status)) /
    (STDDEV(person_age) * STDDEV(loan_status)) AS 'correlation_person_age_status'
FROM 
    credit_risk_dataset;--
    
-- ist dehr schwache korrelation -0.02
-- ab 0.7 satrk
-- unter 0.4 schwach



-- Zusammenfassung der Korrelation:
-- Ältere Personen haben längere Kreditgeschichte.
-- Höhere Kreditbeträge korrelieren mit höheren prozentualen Einkommen.
-- Höhere Einkommen korrelieren mit geringerem Kreditausfallrisiko.
-- Höherer prozentualer Einkommensanteil für Kredit korreliert mit höherem Ausfallrisiko.



-- Fazit:
-- Alter: -- Am wenigsten Risiko bei Personen im Alter von 30 bis 50.
-- Einkommen: Einkommen unter 20.000 erhöht Risiko, umso größer, desto geringere Risikowahrscheinlichkeit.
-- prozentuale Anteil des Kreditbetrags zum jährlichen Einkommen der Person, Zinssatz des Kredits, Kreditbetrags: Umso größer, desto höhere Risikowahrscheinlichkeit.
-- Wohnsitzstatus: Mietzahlung erschwert Kreditrückzahlung (höhere Risikowahrscheinlichkeit bei Mietzahlung).
-- Beschäftigungsdauer: 5-20 Jahre - Mehr Rückzahlung, weniger Risiko; unter 5 und über 20 Jahre - Weniger Rückzahlung, mehr Risiko.
-- Kreditabsichts:
--   - Venture: Mehr Rückzahlung, geringeres Risiko.
--   - Reihenfolge: Debt Consolidation > Medical > Home Improvement.
--   - 26-28% keine Rückzahlung, höheres Risiko.
-- Kreditnote :
--   - Ohne Vergangenheitsausfälle: Geringster Zinssatz in A und B.
--   - Höhere Rückzahlungen in diesen Klassen, geringeres Risiko; andere Klassen sind risikoreicher.
-- Die Länge der Kredithistorie der Person in Jahren.: -- Größere Menge an Nullwerten, Analyse nicht möglich.



-- Ansicht für die Risikobewertung

CREATE VIEW risk_status_view AS
SELECT
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length,
    CASE 
        WHEN loan_grade IN ('A', 'B') AND person_income > 45000 AND loan_status = 0 AND loan_percent_income < 0.3  THEN 'Low Risk'
        WHEN loan_grade IN ('A', 'B') OR loan_percent_income > 0.3 THEN 'Medium Risk'
        WHEN loan_grade IN ('C', 'D') AND person_income > 36000 AND loan_int_rate < 15 THEN 'Medium Risk'
		ELSE "High Risk"
    END AS Risk_Status
FROM 
    credit_risk_dataset;

SELECT * FROM risk_status_view;
DROP VIEW risk_status_view;
SELECT 
    Risk_Status,
	COUNT(*) AS Azahl
FROM risk_status_view
GROUP BY Risk_Status;

-- Anzahl der Risikobewertungsgruppen in Prozent:

SELECT 
    Risk_Status,
    COUNT(*) AS Anzahl,
    CONCAT(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2), '%') AS Prozentsatz
FROM risk_status_view
GROUP BY Risk_Status;








