# USDA NASS Crops Summary

The SQL in this repository extracts yearly county survey data for five crops (corn, cotton, soybeans, rice, wheat) from the USDA NASS main 'crops' FTP file.

USDA NASS FTP: ftp://ftp.nass.usda.gov/quickstats/

Source File: "qs.crops_yyyymmdd.txt.gz" (with recent date replacing yyyymmdd)

The output data is visualized accessible in this Tableau Public dashboard.

https://public.tableau.com/profile/jay1053#!/vizhome/USDANASSDashboard/USDANASSCountyCropYearlySurveys

Data Disclaimer: I am not an expert on this data source and may be mis representing it.

Known Issues:

Dashboard: summing "yield" is incorrect. Yield is a ratio and should be averaged.
