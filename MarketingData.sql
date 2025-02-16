/* Create Tables and import data from CSV files */
CREATE TABLE (

);

/* Set primary keys */
ALTER TABLE campaign_data
ADD PRIMARY KEY (campaignid);

/* 1. Campaign Effectiveness Analysis */
/* Which campaigns had the highest and lowest lead volumes? (top 10 for each) */
SELECT campaignid, leadvolumeindustry
FROM campaign_data
ORDER BY leadvolumeindustry DESC
	LIMIT 10;

SELECT campaignid, leadvolumeindustry
FROM campaign_data
ORDER BY leadvolumeindustry ASC
	LIMIT 10;

/* What is the average cost per lead by region and country? (JOIN Campaign_Data and Region_Country_Mapping) */
SELECT region_country_mapping.country, region_country_mapping.region, ROUND(AVG(CAST(netcostperlead AS NUMERIC)),2)
FROM campaign_data
LEFT OUTER JOIN region_country_mapping
	ON campaign_data.countryid = region_country_mapping.countryid
GROUP BY region_country_mapping.country, region_country_mapping.region;

/* What is the total cost per campaign, and how does it compare across regions? (SUM of Net Cost per Lead × Lead Volume grouped by Region, Country) */
SELECT RCM.region, ROUND(SUM(CAST(CD.netcostperlead AS NUMERIC) * CAST(CD.leadvolumeindustry AS NUMERIC)),2) AS SumCost
FROM campaign_data CD
INNER JOIN region_country_mapping RCM
	ON CD.regionid = RCM.regionid
GROUP BY RCM.region
ORDER BY SumCost DESC;

/* 2. Lead Engagement & Behavior */
/* Count the number of email addresses that contain the name 'tyler' and having a 'senior' job level or a 'CEO' & 'Director' job title associated */
SELECT COUNT(*)
FROM lead_data
WHERE emailaddress LIKE '%tyler%' AND (joblevel ILIKE 'senior' OR jobtitle IN ('CEO', 'Director'));

/* How many leads were generated per industry across all campaigns? (JOIN Lead_Data with Campaign_Data, GROUP BY Industry) */
SELECT CD.industry, COUNT(*) AS TotalLeadVolume
FROM lead_data LD
INNER JOIN campaign_data CD
	ON LD.campaignid = CD.campaignid
GROUP BY CD.industry
ORDER BY TotalLeadVolume DESC;

/* What are the top 5 job titles among all leads? (COUNT on Job Title, ORDER BY DESC, LIMIT 5) */
SELECT jobtitle, COUNT(jobtitle) AS PopularJobs
FROM lead_data
GROUP BY jobtitle
ORDER BY PopularJobs DESC
	LIMIT 5;

/* What is the distribution of job levels within each industry? (JOIN Lead_Data with Campaign_Data, GROUP BY Industry, Job Level) */
SELECT CD.industry, LD.joblevel, COUNT(*)
FROM lead_data LD
INNER JOIN campaign_data CD
	ON LD.campaignid = CD.campaignid
GROUP BY CD.industry, LD.joblevel
ORDER BY joblevel ASC;

/* Which campaigns generated the most leads for high-level job positions (Director, CEO)? (Subquery filtering Job Title) */
SELECT campaignid, count(*) AS TotalLeadVolume
FROM (
	SELECT *
	FROM lead_data
	WHERE jobtitle IN ('Director', 'CEO')
	 )
GROUP BY campaignid
ORDER BY TotalLeadVolume DESC;

/* 3. Email Marketing & Engagement Performance */
/* What is the email open rate per campaign? (Opens ÷ Emails Delivered, GROUP BY Campaign ID) */
SELECT 
	campaignid,
	ROUND(CAST(opens AS NUMERIC) / CAST(emaildelivered AS NUMERIC) * 100, 2) AS OpenRate
FROM campaign_performance
ORDER BY OpenRate DESC;

/* What is the unique click rate per region? (Unique Clicks ÷ Emails Delivered, JOIN Region_Country_Mapping) */
SELECT 
	RCM.region,
	ROUND(AVG(CAST(CP.uniqueclicks AS NUMERIC) / CAST(CP.emaildelivered AS NUMERIC) * 100),2) AS ClickRate
FROM campaign_performance CP
INNER JOIN campaign_data CD
	ON CP.campaignid = CD.campaignid
INNER JOIN region_country_mapping RCM
	ON CD.regionid = RCM.regionid
GROUP BY RCM.region
ORDER BY ClickRate DESC;

/* What is the rank of each campaign in terms of unique opens within each industry segment of the leads it engaged? Filter by the top 5 best ranked? */
WITH industrydata AS (
		SELECT CD.campaignid, CP.uniqueopens, CD.industry, CD.leadvolumeindustry,
				RANK() OVER (PARTITION BY industry ORDER BY uniqueopens DESC) AS ranklead
		FROM campaign_performance CP
		INNER JOIN campaign_data CD
			ON CP.campaignid = CD.campaignid
					  )
SELECT campaignid, uniqueopens, industry, leadvolumeindustry, ranklead
FROM industrydata
WHERE ranklead < 6
ORDER BY INDUSTRY ASC;

/* How the campaigns performed across each region? */
CREATE TEMP TABLE Temp_region_Performance AS
SELECT
	RCM.region,
	SUM(CP.opens) AS Total_opens,
	SUM(CP.uniqueclicks) AS Total_clicks,
	SUM(unsubscribed) AS Total_unsub
FROM region_country_mapping RCM
JOIN campaign_data CD
	ON RCM.regionid = CD.regionid
JOIN campaign_performance CP
	ON CP.campaignid = CD.campaignid
GROUP BY RCM.region;

SELECT * 
FROM Temp_region_Performance
WHERE total_unsub < 150;

/* Create a View for Campaign Performance Overview */
CREATE VIEW Campaign_Performance_View AS
SELECT 
	CD.campaignid,
	CD.industry,
	CD.leadvolumeindustry,
	CP.emaildelivered,
	CP.uniqueopens,
	ROUND(CAST(CP.uniqueopens AS NUMERIC) / CAST(CP.emaildelivered AS NUMERIC) * 100,2) AS Open_Rate,
	CP.uniqueclicks,
	ROUND(CAST(CP.uniqueclicks AS NUMERIC) / CAST(CP.emaildelivered AS NUMERIC) * 100,2) AS Click_Rate
FROM campaign_performance CP
INNER JOIN campaign_data CD
	ON CD.campaignid = CP.campaignid 
ORDER BY click_rate DESC, open_rate DESC;














