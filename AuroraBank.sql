
SELECT * FROM cards_data;
SELECT * FROM transactions_data;
SELECT * FROM mcc_codes;
SELECT * FROM users_data;

---List all users with their age and gender

SELECT 
      id AS User_ID,
      gender,
      current_age, 
      retirement_age
FROM users_data


---Count the number of credit cards issued so far

SELECT
     COUNT (num_cards_issued) AS Total_cards_Issued
FROM cards_data
 

 ---Calculate the Average yearly income of customers

 SELECT 
     ROUND(AVG (yearly_income),1) AS Average_Yearly_Income
 FROM users_data


 ---How many transactions were made using chip?

 SELECT 
      COUNT(use_chip) AS TransactionsMadeWithChip
 FROM transactions_data
 WHERE use_chip = 'Chip Transaction';


 ----Calculate the average credit score by state.

 SELECT merchant_state, AVG(credit_score) AS AverageCreditScoreByState
 FROM transactions_data td
 JOIN users_data ud ON td.client_id = ud.id
 GROUP BY merchant_state;


 ---List all customers who have a credit score below 600 and a yearly income of above $50,000

 SELECT
       id AS ClientID,
       current_age,
       gender,
       credit_score, 
       yearly_income
 FROM users_data 
 WHERE credit_score < 600 AND yearly_income > 50000;


 ---- ---Find total debt and average income by age group

 SELECT 
 CASE 
     WHEN current_age < 25 THEN 'GenZ'
     WHEN current_age BETWEEN 25 AND 40 THEN 'Millenial'
     WHEN current_age BETWEEN 41 AND 60 THEN 'GenX'
    ELSE 'Old'
     END AS Age_Group,
SUM(total_debt) AS Total_debt,
AVG( yearly_income) AS AverageIncome
FROM users_data
GROUP BY 
      CASE 
     WHEN current_age < 25 THEN 'GenZ'
     WHEN current_age BETWEEN 25 AND 40 THEN 'Millenial'
     WHEN current_age BETWEEN 41 AND 60 THEN 'GenX'
    ELSE 'Old'
     END
ORDER BY AverageIncome DESC;


----Find customers with more than 3 cards

SELECT client_id, 
       COUNT(*) AS Num_of_Cards
FROM cards_data
GROUP BY client_id
HAVING COUNT(*) > 3;


----Find top 10 merchants by transaction amount

SELECT TOP 10 merchant_id, SUM(amount) AS TransactionAmount
FROM transactions_data
GROUP BY merchant_id
ORDER BY TransactionAmount DESC


----Find customers whose total debts exeeds their yearly income

SELECT id AS ClientID,
       yearly_income,
     SUM(total_debt) AS TotalDept
 FROM users_data
 WHERE total_debt > yearly_income
 GROUP BY id, yearly_income;


 ---Find the average transaction amount by card type and brand.

SELECT c.card_brand, 
       c.card_type, 
       AVG(t.amount) AS Avg_Transaction
FROM transactions_data t
JOIN cards_data c ON t.card_id = c.id
GROUP BY c.card_brand, c.card_type;


----Find all customers who haven’t changed their card PIN in over 5 years

SELECT 
     client_id,
     year_pin_last_changed
FROM cards_data
WHERE YEAR(GETDATE()) - year_pin_last_changed > 5;


---Calculate average transaction amount per customer

WITH CustomerSpend AS (
    SELECT client_id, SUM(amount) AS Total_Spent, COUNT(*) AS Num_Transactions
    FROM transactions_data
    GROUP BY client_id
)
  SELECT u.id, u.gender, c.Total_Spent, c.Num_Transactions,
       ROUND(c.Total_Spent / NULLIF(c.Num_Transactions, 0), 2) AS Avg_Spend_Per_Transaction
FROM users_data u
JOIN CustomerSpend c ON u.id = c.client_id;


---Find the month with the highest total transaction value

SELECT TOP 1
    MONTH(date) AS TransactionMonth,
    YEAR(date) AS TransactionYear,
    Round(SUM(amount),2) AS TotalValue
FROM transactions_data
GROUP BY YEAR(date), MONTH(date)
ORDER BY TotalValue DESC;


---For each state, find the total number of transactions and the total amount spent

SELECT
    merchant_state,
    COUNT(*) AS TransactionCount,
    SUM(amount) AS TotalAmount
FROM transactions_data
GROUP BY merchant_state;


---What is the distribution of credit limits accross all cards

SELECT
    CASE
        WHEN credit_limit < 1000 THEN 'Under 1k'
        WHEN credit_limit BETWEEN 1000 AND 5000 THEN '1k - 5k'
        WHEN credit_limit BETWEEN 5001 AND 10000 THEN '5k - 10k'
        ELSE 'Over 10k'
    END AS CreditLimitRange,
    COUNT(*) AS NumberOfCards
FROM cards_data
GROUP BY
    CASE
        WHEN credit_limit < 1000 THEN 'Under 1k'
        WHEN credit_limit BETWEEN 1000 AND 5000 THEN '1k - 5k'
        WHEN credit_limit BETWEEN 5001 AND 10000 THEN '5k - 10k'
        ELSE 'Over 10k'
    END
ORDER BY MIN(credit_limit);


---Show average credit limit by card type and brand

SELECT
    card_brand,
    card_type,
    AVG(credit_limit) AS AvgCreditLimit
FROM cards_data
GROUP BY card_brand, card_type;


----Identify the city with the highest number of unique merchants

SELECT TOP 1
    merchant_city,
    COUNT(DISTINCT merchant_id) AS UniqueMerchants
FROM transactions_data
GROUP BY merchant_city
ORDER BY UniqueMerchants DESC;


---Rank customers within their age group based on their total spending

WITH AgeGroupSpending AS (
    SELECT
        ud.id,
        CASE
            WHEN ud.current_age < 30 THEN '20s'
            WHEN ud.current_age BETWEEN 30 AND 39 THEN '30s'
            WHEN ud.current_age BETWEEN 40 AND 49 THEN '40s'
            ELSE '50+'
        END AS AgeGroup,
        SUM(t.amount) AS TotalSpent
    FROM users_data ud
    JOIN transactions_data t ON ud.id = t.client_id
    GROUP BY ud.id, ud.current_age
)
SELECT
    *,
    RANK() OVER (PARTITION BY AgeGroup ORDER BY TotalSpent DESC) AS SpendRankInAgeGroup
FROM AgeGroupSpending;


----Calculate the month-over-month growth rate in total transaction volume

WITH MonthlyVolumes AS (
    SELECT
        YEAR(date) AS Year,
        MONTH(date) AS Month,
        SUM(amount) AS TotalVolume
    FROM transactions_data
    GROUP BY YEAR(date), MONTH(date)
)
SELECT
    Year,
    Month,
    TotalVolume,
    LAG(TotalVolume) OVER (ORDER BY Year, Month) AS PreviousMonthVolume,
    ((TotalVolume - LAG(TotalVolume) OVER (ORDER BY Year, Month)) / LAG(TotalVolume) 
    OVER (ORDER BY Year, Month)) * 100.0 AS GrowthRate
FROM MonthlyVolumes
ORDER BY Year, Month;


----Find the merchants with higher than average transaction error

WITH MerchantStats AS 
(
    SELECT
        merchant_id,
        COUNT(*) AS TotalTransactions,
        SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) AS ErrorTransactions
    FROM transactions_data
    GROUP BY merchant_id
)
SELECT
    merchant_id,
    TotalTransactions,
    ErrorTransactions,
    (ErrorTransactions * 1.0 / TotalTransactions) AS ErrorRate
FROM MerchantStats
WHERE (ErrorTransactions * 1.0 / TotalTransactions) > (
    SELECT (SUM(CASE WHEN errors IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / COUNT(*))
    FROM transactions_data
)
ORDER BY ErrorRate DESC;


----Identify potential fraudulent activity by flagging transactions that are more than 
--- 3 standard deviations above the mean for the specific MCC code and card

WITH MCCStats AS (
    SELECT
        mcc,
        AVG(amount) AS AvgAmount,
        STDEV(amount) AS StdDevAmount
    FROM transactions_data
    GROUP BY mcc
),
FlaggedTransactions AS (
    SELECT
        t.*,
        ms.AvgAmount,
        ms.StdDevAmount,
        (t.amount - ms.AvgAmount) / NULLIF(ms.StdDevAmount, 0) AS ZScore
    FROM transactions_data t
    JOIN MCCStats ms ON t.mcc = ms.mcc
    WHERE ms.StdDevAmount > 0 -- Avoid division by zero
)
SELECT *
FROM FlaggedTransactions
WHERE ZScore > 3;


---Create a customer risk score based on debt-to-income, credit score, and number of recent transaction errors

WITH CustomerMetrics AS (
    SELECT
        ud.id,
        (ud.total_debt / NULLIF(ud.yearly_income, 0)) AS DebtToIncomeRatio,
        ud.credit_score,
        (SELECT COUNT(*) FROM transactions_data t WHERE t.client_id = ud.id AND t.errors IS NOT NULL) AS ErrorCount
    FROM users_data ud
),
NormalizedMetrics AS (
    SELECT
        id,
        -- Normalize Debt-to-Income (higher is riskier)
        (DebtToIncomeRatio - MIN(DebtToIncomeRatio) OVER ()) / (MAX(DebtToIncomeRatio) OVER () - MIN(DebtToIncomeRatio) OVER ()) AS NormDTI,
        -- Normalize Credit Score (lower is riskier, so invert)
        1 - ((credit_score - MIN(credit_score) OVER ()) / (MAX(credit_score) OVER () - MIN(credit_score) OVER ())) AS NormCreditScore,
        -- Normalize Error Count (higher is riskier)
        (ErrorCount - MIN(ErrorCount) OVER ()) / (NULLIF(MAX(ErrorCount) OVER (), 0) - MIN(ErrorCount) OVER ()) AS NormErrors
    FROM CustomerMetrics
)
SELECT
    id,
    (NormDTI * 0.5 + NormCreditScore * 0.3 + NormErrors * 0.2) * 100 AS RiskScore
FROM NormalizedMetrics
ORDER BY RiskScore DESC;


---Find the second most popular merchant category by transaction count for each customer

WITH CustomerMCCRanks AS (
    SELECT
        client_id,
        mcc,
        COUNT(*) AS TransactionCount,
        DENSE_RANK() OVER (PARTITION BY client_id ORDER BY COUNT(*) DESC) AS MCCRank
    FROM transactions_data
    GROUP BY client_id, mcc
)
SELECT
    cmr.client_id,
    mc.Description AS SecondFavoriteMCC,
    cmr.TransactionCount
FROM CustomerMCCRanks cmr
JOIN mcc_codes mc ON cmr.mcc = mc.mcc_id
WHERE cmr.MCCRank = 2;


----For each customer, calculate the rolling 3 months average of their spending

WITH MonthlySpending AS (
    SELECT
        client_id,
        YEAR(date) AS Year,
        MONTH(date) AS Month,
        SUM(amount) AS MonthlySpend
    FROM transactions_data
    GROUP BY client_id, YEAR(date), MONTH(date)
)
SELECT
    client_id,
    Year,
    Month,
    MonthlySpend,
    AVG(MonthlySpend) OVER (
        PARTITION BY client_id
        ORDER BY Year, Month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Rolling3MonthAvg
FROM MonthlySpending
ORDER BY client_id, Year, Month;


----Identify potential fraud, transactions exceeding 2 times the customer’s average transaction amount

WITH AvgTrans AS (
    SELECT client_id, 
    AVG(amount) AS Avg_transaction_Amount
    FROM transactions_data
    GROUP BY client_id
)
SELECT t.id AS Transaction_ID, 
       t.client_id, 
       t.amount, 
       a.Avg_transaction_Amount
FROM transactions_data t
JOIN AvgTrans a ON t.client_id = a.client_id
WHERE t.amount > 2 * a.Avg_transaction_Amount;


----Identify customers at credit risk (low score and high debt-to-income ratio).

SELECT id AS CustomerID, 
       credit_score, 
       yearly_income, 
       total_debt,
       ROUND(CAST(total_debt AS FLOAT)/yearly_income, 2) AS Debt_To_Income_ratio
FROM users_data
WHERE credit_score < 600 AND (CAST(total_debt AS FLOAT)/yearly_income) > 0.5;


---Find the average number of cards per user for each income bracket

SELECT 
  CASE 
    WHEN yearly_income < 40000 THEN 'Low Income'
    WHEN yearly_income BETWEEN 40000 AND 80000 THEN 'Middle Income'
    ELSE 'High Income' 
    END AS Income_Bracket,
  AVG(num_credit_cards) AS Avg_Cards
FROM users_data
GROUP BY 
  CASE 
    WHEN yearly_income < 40000 THEN 'Low Income'
    WHEN yearly_income BETWEEN 40000 AND 80000 THEN 'Middle Income'
    ELSE 'High Income'
    END;


------Find the number of cards per user for each income bracket

SELECT 
  CASE 
    WHEN yearly_income < 40000 THEN 'Low Income'
    WHEN yearly_income BETWEEN 40000 AND 80000 THEN 'Middle Income'
    ELSE 'High Income' 
    END AS Income_Bracket,
  COUNT(num_credit_cards) AS No_Of_Cards
FROM users_data
GROUP BY 
  CASE 
    WHEN yearly_income < 40000 THEN 'Low Income'
    WHEN yearly_income BETWEEN 40000 AND 80000 THEN 'Middle Income'
    ELSE 'High Income'
    END;


----Identify the most common MCC categories for high-income customers (>100,000).

SELECT m.description, COUNT(*) AS Transaction_Count
FROM transactions_data t
JOIN users_data u ON t.client_id = u.id
JOIN mcc_codes m ON t.mcc = m.mcc_id
WHERE u.yearly_income > 100000
GROUP BY m.description
ORDER BY Transaction_Count DESC;

