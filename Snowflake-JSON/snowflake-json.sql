JSON --> Variant

create database ytb1;
create schema learn;

use database ytb1;
use schema learn;

--LOADING A JSON DATA INTO SNOWFLAKE

--step1: creating a stage

create or replace stage json_loading_stage;

--step2:- load that data into the create stage
--put file://'c....*json @json_loading_stage'

--step3:verify the loaded file in the stage using list command
LIST @json_loading_stage;

--step4: create a file format for the stage/source file

create or replace file format my_json_format
type=json
strip_outer_array=true;


--step 5:- create a snowflake table to load the json data from stage

create or replace table eba_register
(
json_data variant
);


--step 6:- load the data from stage into the snowflake table

copy into eba_register
from @json_loading_stage/download-PSDMD-202412290800.json
file_format=(format_name =my_json_format);

--querying the data from snowflake table

select * from eba_register limit 100;

--quering the data from the stage without loading into a table

select
*
from @json_loading_stage/download-PSDMD-202412290800.json
(file_format =>'my_json_format')
limit 100;

select
$1:"CA_OwnerID"::varchar
from @json_loading_stage/download-PSDMD-202412290800.json
(file_format =>'my_json_format')
limit 100;

---How to validate a json file after loading into a table and before processing that data;

select check_json(json_data) as output from eba_register;

--extract the vale from json file into a table.

select * from eba_register limit 100;

select json_data:CA_OwnerID
from eba_register limit 10;

select system$typeof(json_data:CA_OwnerID)
from eba_register limit 10;

select 
json_data:CA_OwnerID::varchar as owner_id,
json_data:EntityCode::varchar as ENT_CODE,
json_data:EntityType::varchar as ENT_TYPE,
TO_DATE(json_data:Properties[0].ENT_AUT[0]::VARCHAR,'yyyy-mm-dd') as date_off,
json_data:Properties[1].ENT_NAT_REF_COD::varchar as ENT_NAT,
json_data:Properties[2].ENT_NAM::varchar as ENTITY_NAME
from eba_register 
limit 10;


select
owner_id,
ENT_CODE,
ENT_TYPE,
max(case when rn=1 then ENT_NAT_REF_COD end) as ENT_NAT_REF_COD,
max(case when rn=2 then entity_name end) as entity_name,
max(case when rn=3 then ENT_COU_RES end) as ENT_COU_RES
from(

select 
json_data:CA_OwnerID::varchar as owner_id,
json_data:EntityCode::varchar as ENT_CODE,
json_data:EntityType::varchar as ENT_TYPE,
flat.value:ENT_NAT_REF_COD::varchar as ENT_NAT_REF_COD,
flat.value:ENT_NAM::varchar as entity_name,
flat.value:ENT_COU_RES::varchar as ENT_COU_RES,
row_number()over( partition by owner_id,ENT_CODE,ENT_TYPE order by owner_id) as rn
from eba_register, 
lateral flatten(input =>json_data,path=>'Properties' )flat
where (ENT_NAT_REF_COD is not null
or entity_name is not null
or ENT_COU_RES is not null)
)t
group by 
owner_id,
ENT_CODE,
ENT_TYPE;












