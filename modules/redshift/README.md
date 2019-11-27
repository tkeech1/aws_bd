Setup Redshift Spectrum to use Glue data source

```
make apply-athena
make start-glue-crawler
```

# To Query the Glue data using Athena, login to Athena and issue the following SQL
```
SELECT description,
         count(*)
FROM orderlogs
WHERE country='France'
        AND year='2019'
GROUP BY  description; 
```

# Login to Refshift and run the following SQL to import the data from AWS Glue
```
create external schema orderlog_schema from data catalog database 'orderlogs' iam_role 'arn:aws:iam::224809215835:role/redshift_role'
region 'us-east-1';
```