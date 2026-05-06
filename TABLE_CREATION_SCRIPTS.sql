/* ============================================================
   TELCO PROJECT - TABLE CREATION SCRIPTS
   Database: Oracle XE
   Author: Neptune-Stars
   ============================================================ */

/*
/* Drop tables first so the script can be re-run safely during testing. */
DROP TABLE MONTHLY_STATS CASCADE CONSTRAINTS;
DROP TABLE CUSTOMERS CASCADE CONSTRAINTS;
DROP TABLE TARIFFS CASCADE CONSTRAINTS;
*/

/* ============================================================
   TARIFFS TABLE
   Stores telecom package definitions.
   DATA_LIMIT, MINUTE_LIMIT, and SMS_LIMIT represent the included
   package limits for each tariff.
   ============================================================ */
CREATE TABLE TARIFFS (
    TARIFF_ID     NUMBER        NOT NULL,
    NAME          VARCHAR2(100) NOT NULL,
    MONTHLY_FEE   NUMBER(10,2)  NOT NULL,
    DATA_LIMIT    NUMBER(12,2)  NOT NULL,
    MINUTE_LIMIT  NUMBER        NOT NULL,
    SMS_LIMIT     NUMBER        NOT NULL,

    CONSTRAINT PK_TARIFFS PRIMARY KEY (TARIFF_ID),
    CONSTRAINT UQ_TARIFFS_NAME UNIQUE (NAME),
    CONSTRAINT CHK_TARIFFS_MONTHLY_FEE CHECK (MONTHLY_FEE >= 0),
    CONSTRAINT CHK_TARIFFS_DATA_LIMIT CHECK (DATA_LIMIT >= 0),
    CONSTRAINT CHK_TARIFFS_MINUTE_LIMIT CHECK (MINUTE_LIMIT >= 0),
    CONSTRAINT CHK_TARIFFS_SMS_LIMIT CHECK (SMS_LIMIT >= 0)
);

/* ============================================================
   CUSTOMERS TABLE
   Stores customer master data.
   SIGNUP_DATE is imported as DATE using the DD/MM/YYYY format.
   ============================================================ */
CREATE TABLE CUSTOMERS (
    CUSTOMER_ID   NUMBER         NOT NULL,
    NAME          VARCHAR2(100)  NOT NULL,
    CITY          VARCHAR2(100)  NOT NULL,
    SIGNUP_DATE   DATE           NOT NULL,
    TARIFF_ID     NUMBER         NOT NULL,

    CONSTRAINT PK_CUSTOMERS PRIMARY KEY (CUSTOMER_ID),
    CONSTRAINT FK_CUSTOMERS_TARIFFS
        FOREIGN KEY (TARIFF_ID)
        REFERENCES TARIFFS (TARIFF_ID)
);

/* ============================================================
   MONTHLY_STATS TABLE
   Stores this month's customer usage and payment information.
   Some customers may be missing from this table because of the
   insertion error described in the assignment.
   ============================================================ */
CREATE TABLE MONTHLY_STATS (
    ID              NUMBER        NOT NULL,
    CUSTOMER_ID     NUMBER        NOT NULL,
    DATA_USAGE      NUMBER(12,2)  NOT NULL,
    MINUTE_USAGE    NUMBER        NOT NULL,
    SMS_USAGE       NUMBER        NOT NULL,
    PAYMENT_STATUS  VARCHAR2(30)  NOT NULL,

    CONSTRAINT PK_MONTHLY_STATS PRIMARY KEY (ID),
    CONSTRAINT UQ_MONTHLY_STATS_CUSTOMER UNIQUE (CUSTOMER_ID),
    CONSTRAINT FK_MONTHLY_STATS_CUSTOMERS
        FOREIGN KEY (CUSTOMER_ID)
        REFERENCES CUSTOMERS (CUSTOMER_ID),
    CONSTRAINT CHK_MONTHLY_STATS_DATA_USAGE CHECK (DATA_USAGE >= 0),
    CONSTRAINT CHK_MONTHLY_STATS_MINUTE_USAGE CHECK (MINUTE_USAGE >= 0),
    CONSTRAINT CHK_MONTHLY_STATS_SMS_USAGE CHECK (SMS_USAGE >= 0),
CONSTRAINT CHK_MONTHLY_STATS_PAYMENT_STATUS
    CHECK (PAYMENT_STATUS IN ('PAID', 'UNPAID', 'LATE'))
);

/* ============================================================
   INDEXES
   These indexes support joins, filtering, and grouping used in
   the project queries.
   ============================================================ */

CREATE INDEX IDX_CUSTOMERS_TARIFF_ID
ON CUSTOMERS (TARIFF_ID);

CREATE INDEX IDX_CUSTOMERS_SIGNUP_DATE
ON CUSTOMERS (SIGNUP_DATE);

CREATE INDEX IDX_CUSTOMERS_CITY
ON CUSTOMERS (CITY);

CREATE INDEX IDX_MONTHLY_STATS_PAYMENT_STATUS
ON MONTHLY_STATS (PAYMENT_STATUS);