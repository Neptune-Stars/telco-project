/* ============================================================
   TELCO PROJECT - SQL SOLUTIONS
   Database: Oracle XE
   Tables:
     - CUSTOMERS
     - TARIFFS
     - MONTHLY_STATS
   ============================================================ */

/* ============================================================
   1.1 List the customers who are subscribed to the 'Kobiye Destek' tariff.

   Approach:
   This query joins CUSTOMERS with TARIFFS by using the TARIFF_ID foreign key relationship.
   The tariff name is stored in the TARIFFS table, so filtering directly on CUSTOMERS would not be enough.
   I use an INNER JOIN because only customers with a valid matching tariff should be returned.
   ============================================================ */

SELECT
    c.CUSTOMER_ID,
    c.NAME AS CUSTOMER_NAME,
    c.CITY,
    c.SIGNUP_DATE,
    t.NAME AS TARIFF_NAME
FROM CUSTOMERS c
JOIN TARIFFS t
    ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.NAME = 'Kobiye Destek'
ORDER BY c.CUSTOMER_ID;


/* ============================================================
   1.2 Find the newest customer who subscribed to the 'Kobiye Destek' tariff.

   Approach:
   This query again joins CUSTOMERS and TARIFFS so that the tariff name can be used as a filter.
   The newest customer is determined by SIGNUP_DATE, not by CUSTOMER_ID, because customer IDs may not reflect chronological signup order.
   The result is ordered by SIGNUP_DATE descending and then CUSTOMER_ID descending as a tie-breaker, returning only the first row.
   ============================================================ */

SELECT
    c.CUSTOMER_ID,
    c.NAME AS CUSTOMER_NAME,
    c.CITY,
    c.SIGNUP_DATE,
    t.NAME AS TARIFF_NAME
FROM CUSTOMERS c
JOIN TARIFFS t
    ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.NAME = 'Kobiye Destek'
ORDER BY c.SIGNUP_DATE DESC, c.CUSTOMER_ID DESC
FETCH FIRST 1 ROW ONLY;


/* ============================================================
   2.1 Find the distribution of tariffs among the customers.

   Approach:
   This query groups customers by tariff to show how many customers are subscribed to each package.
   The JOIN is needed because the customer table only stores TARIFF_ID, while the readable tariff name is stored in TARIFFS.
   I also calculate the percentage of total customers using COUNT(*) divided by the total number of customers.
   ============================================================ */

SELECT
    t.TARIFF_ID,
    t.NAME AS TARIFF_NAME,
    COUNT(c.CUSTOMER_ID) AS CUSTOMER_COUNT,
    ROUND(COUNT(c.CUSTOMER_ID) * 100 / SUM(COUNT(c.CUSTOMER_ID)) OVER (), 2) AS PERCENTAGE
FROM TARIFFS t
LEFT JOIN CUSTOMERS c
    ON t.TARIFF_ID = c.TARIFF_ID
GROUP BY t.TARIFF_ID, t.NAME
ORDER BY CUSTOMER_COUNT DESC;


/* ============================================================
   3.1 Identify the earliest customers to sign up.

   Approach:
   This query finds the minimum SIGNUP_DATE from the CUSTOMERS table.
   It then returns all customers whose signup date equals that earliest date.
   This is better than sorting by CUSTOMER_ID because the assignment explicitly warns that the earliest customers may not have the lowest IDs.
   ============================================================ */

SELECT
    CUSTOMER_ID,
    NAME AS CUSTOMER_NAME,
    CITY,
    SIGNUP_DATE,
    TARIFF_ID
FROM CUSTOMERS
WHERE SIGNUP_DATE = (
    SELECT MIN(SIGNUP_DATE)
    FROM CUSTOMERS
)
ORDER BY CUSTOMER_ID;


/* ============================================================
   3.2 Find the distribution of these earliest customers across different cities.

   Approach:
   This query first identifies the earliest signup date using a subquery.
   It then filters customers to only those who signed up on that date and groups them by city.
   Counting by city shows the geographic distribution of the first customers instead of only listing individual records.
   ============================================================ */

SELECT
    CITY,
    COUNT(*) AS EARLIEST_CUSTOMER_COUNT
FROM CUSTOMERS
WHERE SIGNUP_DATE = (
    SELECT MIN(SIGNUP_DATE)
    FROM CUSTOMERS
)
GROUP BY CITY
ORDER BY EARLIEST_CUSTOMER_COUNT DESC, CITY;


/* ============================================================
   4.1 Identify the IDs of customers whose monthly records are missing.

   Approach:
   This query uses a LEFT JOIN from CUSTOMERS to MONTHLY_STATS.
   If a customer has no matching monthly record, the MONTHLY_STATS customer ID will be NULL after the join.
   This is the correct anti-join pattern for finding customers that exist in the master customer table but are missing from the monthly usage table.
   ============================================================ */

SELECT
    c.CUSTOMER_ID,
    c.NAME AS CUSTOMER_NAME,
    c.CITY,
    c.TARIFF_ID
FROM CUSTOMERS c
LEFT JOIN MONTHLY_STATS ms
    ON c.CUSTOMER_ID = ms.CUSTOMER_ID
WHERE ms.CUSTOMER_ID IS NULL
ORDER BY c.CUSTOMER_ID;


/* ============================================================
   4.2 Find the distribution of missing customers across different cities.

   Approach:
   This query uses the same missing-record logic as the previous query.
   Instead of returning each missing customer individually, it groups the missing customers by CITY.
   This makes it easier to see whether the insertion error is randomly distributed or concentrated in certain cities.
   ============================================================ */

SELECT
    c.CITY,
    COUNT(*) AS MISSING_CUSTOMER_COUNT
FROM CUSTOMERS c
LEFT JOIN MONTHLY_STATS ms
    ON c.CUSTOMER_ID = ms.CUSTOMER_ID
WHERE ms.CUSTOMER_ID IS NULL
GROUP BY c.CITY
ORDER BY MISSING_CUSTOMER_COUNT DESC, c.CITY;


/* ============================================================
   5.1 Find customers who have used at least 75% of their data limit.

   Approach:
   This query joins CUSTOMERS, TARIFFS, and MONTHLY_STATS because the data usage is in MONTHLY_STATS while the data limit is in TARIFFS.
   It filters out tariffs with a zero data limit to avoid division by zero and to avoid treating no-data packages incorrectly.
   A customer qualifies if DATA_USAGE is greater than or equal to 75% of the tariff's DATA_LIMIT.
   ============================================================ */

SELECT
    c.CUSTOMER_ID,
    c.NAME AS CUSTOMER_NAME,
    c.CITY,
    t.NAME AS TARIFF_NAME,
    ms.DATA_USAGE,
    t.DATA_LIMIT,
    ROUND(ms.DATA_USAGE * 100 / t.DATA_LIMIT, 2) AS DATA_USAGE_PERCENT
FROM CUSTOMERS c
JOIN TARIFFS t
    ON c.TARIFF_ID = t.TARIFF_ID
JOIN MONTHLY_STATS ms
    ON c.CUSTOMER_ID = ms.CUSTOMER_ID
WHERE t.DATA_LIMIT > 0
  AND ms.DATA_USAGE >= t.DATA_LIMIT * 0.75
ORDER BY DATA_USAGE_PERCENT DESC, c.CUSTOMER_ID;


/* ============================================================
   5.2 Identify customers who have completely exhausted all package limits.

   Approach:
   This query compares each customer's monthly usage values against the package limits of their tariff.
   A customer is considered to have exhausted all limits only if data usage, minute usage, and SMS usage are all greater than or equal to their corresponding limits.
   I require all three conditions at the same time because the requirement says all package limits, not just one package limit.
   ============================================================ */

SELECT
    c.CUSTOMER_ID,
    c.NAME AS CUSTOMER_NAME,
    c.CITY,
    t.NAME AS TARIFF_NAME,
    ms.DATA_USAGE,
    t.DATA_LIMIT,
    ms.MINUTE_USAGE,
    t.MINUTE_LIMIT,
    ms.SMS_USAGE,
    t.SMS_LIMIT
FROM CUSTOMERS c
JOIN TARIFFS t
    ON c.TARIFF_ID = t.TARIFF_ID
JOIN MONTHLY_STATS ms
    ON c.CUSTOMER_ID = ms.CUSTOMER_ID
WHERE ms.DATA_USAGE >= t.DATA_LIMIT
  AND ms.MINUTE_USAGE >= t.MINUTE_LIMIT
  AND ms.SMS_USAGE >= t.SMS_LIMIT
ORDER BY c.CUSTOMER_ID;


/* ============================================================
   6.1 Find the customers who have unpaid fees.

   Approach:
   This query joins CUSTOMERS with MONTHLY_STATS to connect customer identity with payment information.
   The filter uses PAYMENT_STATUS = 'UNPAID' because unpaid status is stored in the monthly statistics table.
   I also join TARIFFS so the result includes the tariff name and monthly fee, which makes the unpaid customer list more informative.
   ============================================================ */

SELECT
    c.CUSTOMER_ID,
    c.NAME AS CUSTOMER_NAME,
    c.CITY,
    t.NAME AS TARIFF_NAME,
    t.MONTHLY_FEE,
    ms.PAYMENT_STATUS
FROM CUSTOMERS c
JOIN MONTHLY_STATS ms
    ON c.CUSTOMER_ID = ms.CUSTOMER_ID
JOIN TARIFFS t
    ON c.TARIFF_ID = t.TARIFF_ID
WHERE ms.PAYMENT_STATUS = 'UNPAID'
ORDER BY t.MONTHLY_FEE DESC, c.CUSTOMER_ID;


/* ============================================================
   6.2 Find the distribution of all payment statuses across different tariffs.

   Approach:
   This query groups records by tariff and payment status.
   The JOINs are needed because payment status is in MONTHLY_STATS, while tariff names are stored in TARIFFS through the CUSTOMERS table.
   The result shows how many customers are in each payment status for each tariff, which is useful for comparing payment behavior across packages.
   ============================================================ */

SELECT
    t.TARIFF_ID,
    t.NAME AS TARIFF_NAME,
    ms.PAYMENT_STATUS,
    COUNT(*) AS CUSTOMER_COUNT
FROM MONTHLY_STATS ms
JOIN CUSTOMERS c
    ON ms.CUSTOMER_ID = c.CUSTOMER_ID
JOIN TARIFFS t
    ON c.TARIFF_ID = t.TARIFF_ID
GROUP BY t.TARIFF_ID, t.NAME, ms.PAYMENT_STATUS
ORDER BY t.TARIFF_ID, ms.PAYMENT_STATUS;