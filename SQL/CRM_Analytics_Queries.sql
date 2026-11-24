create database crm_project;

select*from load_table;
select*from opportunity_product;
select*from user_table;
select*from account;
select*from opportunity_table;

show tables;

-- aggregate functions

show columns from load_table;
select count(leadid) from load_table;

select*from opportunity_table;
select sum(amount) from opportunity_table;

select sum(expectedamount) from opportunity_table;

SELECT
    Converted,
    COUNT(*) AS lead_count
FROM load_table
GROUP BY Converted;

-- window functions
#Rank leads by Pardot score.

SELECT
    LeadID,
    LeadSource,
    PardotScore,
    RANK() OVER (
        ORDER BY PardotScore DESC
    ) AS score_rank
FROM load_table
WHERE PardotScore IS NOT NULL;


#Compare each opportunity amount with the previous opportunity amount
SELECT
    OpportunityID,
    Stage,
    Amount,
    LAG(Amount) OVER (
        ORDER BY CloseDate, OpportunityID
    ) AS previous_amount
FROM opportunity_table
WHERE Amount IS NOT NULL;

-- joins
#Find opportunities with their corresponding account names.

SELECT
    o.OpportunityID,
    o.Stage,
    o.Amount,
    a.AccountName
FROM opportunity_table o
LEFT JOIN account a
    ON o.AccountId = a.AccountID;
    
#Find accounts without opportunities.
    
    SELECT
    a.accountiD,
    a.AccountName
FROM account a
LEFT JOIN opportunity_table o
    ON a.AccountID = o.AccountID
WHERE o.OpportunityID IS NULL;

#Find product details along with opportunity stage and amount.

SELECT
    p.ProductName,
    p.Quantity,
    p.TotalPrice,
    o.OpportunityID,
    o.Stage,
    o.Amount
FROM opportunity_product p
INNER JOIN opportunity_table o
    ON p.OpportunityID = o.OpportunityID;
    
-- stored procedures
    
   # Create a procedure to find opportunities by stage.
   call crm_project.GetOpportunitiesByStage('closed lost');
   
   #Create a procedure that returns the number of accounts in a country.
select*from account;
set @p_count = 0;
call crm_project.GetAccountCountByCountry('usa', @p_count);
select @p_count;

-- triggers

#Create an audit table for opportunity amount changes.

CREATE TABLE opportunity_amount_audit (
    audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    opportunity_id VARCHAR(30),
    old_amount DECIMAL(15,2),
    new_amount DECIMAL(15,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

#Create a trigger to prevent negative opportunity amounts.

DELIMITER //

CREATE TRIGGER trg_prevent_negative_amount
BEFORE UPDATE ON opportunity_table
FOR EACH ROW
BEGIN
    IF NEW.Amount < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Opportunityamountcannotbenegative';
    END IF;
END //

DELIMITER ;
-- For production data, add a corresponding BEFORE INSERT trigger if negative amounts must also be prohibited during insertion. Existing data should be validated separately.
show triggers;

-- views

#Create a view for converted leads.

CREATE  VIEW vw_converted_leads AS
SELECT
    LeadID,
    LeadSource,
    ConvertedAccountID,
    ConvertedOpportunityID,
    CreatedDate
FROM load_table
WHERE Converted = 1;

select*from vw_converted_leads;

#Create a view for opportunity summaries.

CREATE OR REPLACE VIEW opportunity_summary AS
SELECT
    OpportunityID,
    AccountID,
    Stage,
    Amount,
    CloseDate,
    Won,
    Probability
FROM opportunity_table;

select*from opportunity_summary;



   
   