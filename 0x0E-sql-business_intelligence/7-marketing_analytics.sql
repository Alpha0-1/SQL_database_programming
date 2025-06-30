/*
 * File: 7-marketing_analytics.sql
 * Description: Perform marketing analysis
 * 
 * This script provides SQL queries to analyze marketing data:
 * - Campaign Performance
 * - ROAS (Return on Ad Spend)
 * - Customer Acquisition Cost (CAC)
 * - Marketing Attribution
 */

/*
 * Configuration Section
 * 
 * Modify these values to match your database schema
 */
USE business_intelligence_db;

/*
 * Campaign Performance
 * 
 * Provides metrics on marketing campaign effectiveness
 */
SELECT 
    campaign_id,
    campaign_name,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    ROUND(
        (SUM(clicks) / SUM(impressions)) * 100
        , 2
    ) AS click-through_rate,
    ROUND(
        SUM(sales) / SUM(ad_spend)
        , 2
    ) AS ROAS
FROM 
    marketing_campaigns
WHERE 
    campaign_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    campaign_id, campaign_name
ORDER BY 
    ROAS DESC;

/*
 * Customer Acquisition Cost (CAC)
 * 
 * Calculates cost to acquire a new customer
 */
SELECT 
    SUM(ad_spend) / COUNT(DISTINCT(customer_id)) AS customer_acquisition_cost,
    ROUND(
        (SUM(ad_spend) / COUNT(DISTINCT(customer_id))) / (SUM(order_amount) / COUNT(DISTINCT(customer_id)))
        , 2
    ) AS CAC_ratio
FROM 
    marketing_campaigns
LEFT JOIN 
    orders ON marketing_campaigns.campaign_id = orders.campaign_id
WHERE 
    campaign_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Marketing Attribution
 * 
 * Provides attribution across marketing channels
 */
SELECT 
    channel,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    ROUND(
        (SUM(clicks) / SUM(impressions)) * 100
        , 2
    ) AS click-through_rate,
    ROUND(
        SUM(sales) / SUM(ad_spend)
        , 2
    ) AS ROAS
FROM 
    marketing_channels
WHERE 
    campaign_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    channel
ORDER BY 
    ROAS DESC;

/*
 * Marketing Funnel Analysis
 * 
 * Provides metrics on marketing funnel stages
 */
SELECT 
    'Awareness' AS funnel_stage,
    COUNT(DISTINCT(ad_id)) AS total_ads,
    SUM(impressions) AS total_impressions,
    ROUND(AVG(impressions), 2) AS average_impressions
FROM 
    marketing_ads
WHERE 
    ad_date BETWEEN '2023-01-01' AND '2023-12-31'

UNION ALL

SELECT 
    'Engagement' AS funnel_stage,
    COUNT(DISTINCT(post_id)) AS total_posts,
    SUM(engagements) AS total_engagements,
    ROUND(AVG(engagements), 2) AS average_engagements
FROM 
    marketing_posts
WHERE 
    post_date BETWEEN '2023-01-01' AND '2023-12-31'

UNION ALL

SELECT 
    'Conversion' AS funnel_stage,
    COUNT(DISTINCT(campaign_id)) AS total_campaigns,
    SUM(sales) AS total_sales,
    ROUND(AVG(sales), 2) AS average_sales
FROM 
    marketing_campaigns
WHERE 
    campaign_date BETWEEN '2023-01-01' AND '2023-12-31';

/*
 * Usage Notes:
 * 1. Replace the date ranges with appropriate values for your analysis
 * 2. Adjust column names and table names to match your database schema
 * 3. Add additional marketing metrics as needed for your organization
 *
 * Common Extensions:
 * - Add social media performance metrics
 * - Include email marketing analysis
 * - Add A/B test analysis
 */
