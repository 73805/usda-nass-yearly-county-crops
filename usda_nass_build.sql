-- create table of all text types for loading flexilibity
CREATE TABLE crops_demo (
  ID SERIAL PRIMARY KEY,
  SOURCE_DESC text, 
  SECTOR_DESC text, 
  GROUP_DESC text, 
  COMMODITY_DESC text, 
  CLASS_DESC text, 
  PRODN_PRACTICE_DESC text, 
  UTIL_PRACTICE_DESC text, 
  STATISTICCAT_DESC text, 
  UNIT_DESC text, 
  SHORT_DESC text, 
  DOMAIN_DESC text, 
  DOMAINCAT_DESC text, 
  AGG_LEVEL_DESC text, 
  STATE_ANSI text, 
  STATE_FIPS_CODE text, 
  STATE_ALPHA text, 
  STATE_NAME text, 
  ASD_CODE text, 
  ASD_DESC text, 
  COUNTY_ANSI text, 
  COUNTY_CODE text, 
  COUNTY_NAME text, 
  REGION_DESC text, 
  ZIP_5 text, 
  WATERSHED_CODE text, 
  WATERSHED_DESC text, 
  CONGR_DISTRICT_CODE text, 
  COUNTRY_CODE text, 
  COUNTRY_NAME text, 
  LOCATION_DESC text, 
  YEAR text, 
  FREQ_DESC text, 
  BEGIN_CODE text, 
  END_CODE text, 
  REFERENCE_PERIOD_DESC text, 
  WEEK_ENDING text, 
  LOAD_TIME text, 
  VALUE text, 
  CV_PERCENT text
);

-- copy in data from tsv file
COPY crops_demo (
  SOURCE_DESC, 
  SECTOR_DESC, 
  GROUP_DESC, 
  COMMODITY_DESC, 
  CLASS_DESC, 
  PRODN_PRACTICE_DESC, 
  UTIL_PRACTICE_DESC, 
  STATISTICCAT_DESC, 
  UNIT_DESC, 
  SHORT_DESC, 
  DOMAIN_DESC, 
  DOMAINCAT_DESC, 
  AGG_LEVEL_DESC, 
  STATE_ANSI, 
  STATE_FIPS_CODE, 
  STATE_ALPHA, 
  STATE_NAME, 
  ASD_CODE, 
  ASD_DESC, 
  COUNTY_ANSI, 
  COUNTY_CODE, 
  COUNTY_NAME, 
  REGION_DESC, 
  ZIP_5, 
  WATERSHED_CODE, 
  WATERSHED_DESC, 
  CONGR_DISTRICT_CODE, 
  COUNTRY_CODE, 
  COUNTRY_NAME, 
  LOCATION_DESC, 
  YEAR, 
  FREQ_DESC, 
  BEGIN_CODE, 
  END_CODE, 
  REFERENCE_PERIOD_DESC, 
  WEEK_ENDING, 
  LOAD_TIME, 
  VALUE, 
  CV_PERCENT
)
FROM '/Users/jsobel/Desktop/crops.txt' 
DELIMITER E'\t';

-- remove headers (probably doable in previou step)
delete from crops_demo where id = 1;

-- create copy of table structure for additional cleaning
create table crops_ltd (like crops_demo including all)

-- bringing together all the filter steps...
insert into crops_ltd
  select * from crops_demo
  where commodity_desc in ('CORN', 'COTTON', 'RICE', 'SOYBEANS', 'WHEAT')
    and statisticcat_desc in ('AREA HARVESTED', 'AREA PLANTED', 'PRODUCTION', 'YIELD')
    and year >= '1990'
    and source_desc = 'SURVEY'
    and freq_desc = 'ANNUAL'
    and reference_period_desc = 'YEAR'
    and agg_level_desc = 'COUNTY'
    and country_name = 'UNITED STATES'
     -- in absence of informed replacement
    and value not in ('(D)', '(Z)')
    and coalesce(county_ansi, county_code) is not null
    and coalesce(county_ansi, county_code) <> ''
    and coalesce(state_ansi, state_fips_code) is not null
    and coalesce(state_ansi, state_fips_code) <> ''
    -- filter out redundant crop sub type
    and not (commodity_desc = 'WHEAT' and class_desc = 'ALL CLASSES')
    -- filter out atypical measurement units
    and (
         (statisticcat_desc IN ('AREA HARVESTED', 'AREA PLANTED') and unit_desc = 'ACRES')
      or (commodity_desc IN ('CORN', 'SOYBEANS', 'WHEAT') and statisticcat_desc = 'PRODUCTION' and unit_desc = 'BU')
      or (commodity_desc IN ('CORN', 'SOYBEANS', 'WHEAT') and statisticcat_desc = 'YIELD' and unit_desc = 'BU / ACRE')
      or (commodity_desc IN ('COTTON', 'RICE') and statisticcat_desc = 'YIELD' and unit_desc = 'LB / ACRE')
      or (commodity_desc = 'COTTON' and statisticcat_desc = 'PRODUCTION' and unit_desc = '480 LB BALES')
      or (commodity_desc = 'RICE' and statisticcat_desc = 'PRODUCTION' and unit_desc = 'CWT')
    );

-- create reduced/renamed column space 
create table crops_cleaned (
  id SERIAL PRIMARY KEY,
  year integer,
  state_name text,
  county_name text,
  state_ansi text,
  county_ansi text,
  county_fips text,
  crop text,
  crop_class text,
  measurement_type text,
  measurement_units text,
  value decimal
);

insert into crops_cleaned (
  year,
  state_name,
  county_name,
  state_ansi,
  county_ansi,
  county_fips,
  crop,
  crop_class,
  measurement_type,
  measurement_units,
  value
)
select year::int as year,
       state_name,
       county_name,
       coalesce(state_ansi, state_fips_code)::text as state_ansi,
       coalesce(county_ansi, county_code)::text as county_ansi,
       coalesce(state_ansi, state_fips_code)::text || coalesce(county_ansi, county_code)::text as county_fips,
       commodity_desc as crop, 
       class_desc as crop_class,
       statisticcat_desc as measurement_type,
       unit_desc as measurement_units,
       replace(value, ',', '')::decimal as value
from crops_ltd;

-- copy out to file for tableau linking
COPY crops_cleaned to '/Users/jsobel/Desktop/crops_cleaned.csv' csv header;
