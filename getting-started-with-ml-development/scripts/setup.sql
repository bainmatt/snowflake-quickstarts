-- Using ACCOUNTADMIN, create a new role for this demo
USE ROLE ACCOUNTADMIN;
SET USERNAME = (SELECT CURRENT_USER());
SELECT $USERNAME;
CREATE OR REPLACE ROLE ML_MODEL_HOL_USER;

-- Grant new role to user
GRANT ROLE ML_MODEL_HOL_USER to USER identifier($USERNAME);

-- Grant applicable permissions to new role
GRANT CREATE DATABASE ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT CREATE ROLE ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT CREATE APPLICATION ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;
GRANT IMPORT SHARE ON ACCOUNT TO ROLE ML_MODEL_HOL_USER;

-- Switch to the new role
USE ROLE ML_MODEL_HOL_USER;

-- Create the internals
CREATE OR REPLACE WAREHOUSE ML_HOL_WH;  -- by default creates XS Std. Warehouse
CREATE OR REPLACE DATABASE ML_HOL_DB;
CREATE OR REPLACE SCHEMA ML_HOL_SCHEMA;

-- Create a stage to store model assets
CREATE OR REPLACE STAGE ML_HOL_ASSETS;

-- Create CSV format
CREATE FILE FORMAT IF NOT EXISTS ML_HOL_DB.ML_HOL_SCHEMA.CSVFORMAT
  SKIP_HEADER = 1
  TYPE = 'CSV';

-- Create external stage with the csv format to stage the diamonds dataset
CREATE STAGE IF NOT EXISTS ML_HOL_DB.ML_HOL_SCHEMA.DIAMONDS_ASSETS
  FILE_FORMAT = ML_HOL_DB.ML_HOL_SCHEMA.CSVFORMAT
  URL = 's3://sfquickstarts/intro-to-machine-learning-with-snowpark-ml-for-python/diamonds.csv';

-- GitHub integration --------------------------------------------------------

-- Note: The following steps pull files directly from the Snowflake Labs
-- repo into your Snowflake account. You can run them as Snowflake-hosted
-- notebooks and Streamlit apps.
--
-- If you prefer to work locally (using this cloned repo in Jupyter/VSCode),
-- you can safely skip these steps.

-- Create network rule to allow all external access from Notebook
-- [MB] NOTE: External access not supported for trial account.
-- Disable all queries targeting this network rule.
CREATE OR REPLACE NETWORK RULE allow_all_rule
  TYPE = 'HOST_PORT'
  MODE= 'EGRESS'
  VALUE_LIST = ('0.0.0.0:443','0.0.0.0:80');

-- [MB] NOTE: External access not supported for trial account.
-- CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION allow_all_integration
--   ALLOWED_NETWORK_RULES = (allow_all_rule)
--   ENABLED = true;

-- [MB] NOTE: External access not supported for trial account.
-- GRANT USAGE ON INTEGRATION allow_all_integration TO ROLE ML_MODEL_HOL_USER;

-- Create an API integration with GitHub
CREATE OR REPLACE API INTEGRATION GITHUB_INTEGRATION_ML_HOL
  api_provider = git_https_api
  api_allowed_prefixes = ('https://github.com/')
  enabled = true
  comment = 'Git integration with Snowflake Demo GitHub Repository.';

-- Create the integration with the GitHub demo repository
CREATE OR REPLACE GIT REPOSITORY GITHUB_INTEGRATION_ML_HOL
  ORIGIN = 'https://github.com/Snowflake-Labs/sfguide-intro-to-machine-learning-with-snowflake-ml-for-python.git'
  API_INTEGRATION = 'GITHUB_INTEGRATION_ML_HOL'
  COMMENT = 'GitHub Repository';

-- Fetch most recent files from GitHub repository
ALTER GIT REPOSITORY GITHUB_INTEGRATION_ML_HOL FETCH;

-- Copy notebooks into Snowflake & configure runtime settings
CREATE OR REPLACE NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_DATA_INGEST
FROM '@ML_HOL_DB.ML_HOL_SCHEMA.GITHUB_INTEGRATION_ML_HOL/branches/main'
MAIN_FILE = 'notebooks/0_start_here.ipynb'
QUERY_WAREHOUSE = ML_HOL_WH
RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
COMPUTE_POOL = 'SYSTEM_COMPUTE_POOL_CPU'
IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600;

ALTER NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_DATA_INGEST
ADD LIVE VERSION FROM LAST;
-- [MB] NOTE: External access not supported for trial account.
-- ALTER NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_DATA_INGEST
-- SET EXTERNAL_ACCESS_INTEGRATIONS = ('allow_all_integration');

CREATE OR REPLACE NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_FEATURE_TRANSFORM
FROM '@ML_HOL_DB.ML_HOL_SCHEMA.GITHUB_INTEGRATION_ML_HOL/branches/main'
MAIN_FILE = 'notebooks/1_sf_nb_snowflake_ml_feature_transformations.ipynb'
QUERY_WAREHOUSE = ML_HOL_WH
RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
COMPUTE_POOL = 'SYSTEM_COMPUTE_POOL_CPU'
IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600;

ALTER NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_FEATURE_TRANSFORM
ADD LIVE VERSION FROM LAST;
-- [MB] NOTE: External access not supported for trial account.
-- ALTER NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_FEATURE_TRANSFORM
-- SET EXTERNAL_ACCESS_INTEGRATIONS = ('allow_all_integration');

CREATE OR REPLACE NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_MODELING
FROM '@ML_HOL_DB.ML_HOL_SCHEMA.GITHUB_INTEGRATION_ML_HOL/branches/main'
MAIN_FILE = 'notebooks/2_sf_nb_snowflake_ml_model_training_inference.ipynb'
QUERY_WAREHOUSE = ML_HOL_WH
RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
COMPUTE_POOL = 'SYSTEM_COMPUTE_POOL_CPU'
IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600;

ALTER NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_MODELING
ADD LIVE VERSION FROM LAST;
-- [MB] NOTE: External access not supported for trial account.
-- ALTER NOTEBOOK ML_HOL_DB.ML_HOL_SCHEMA.ML_HOL_MODELING
-- SET EXTERNAL_ACCESS_INTEGRATIONS = ('allow_all_integration');

-- Create Streamlit
CREATE OR REPLACE STREAMLIT ML_HOL_STREAMLIT_APP
FROM '@ML_HOL_DB.ML_HOL_SCHEMA.GITHUB_INTEGRATION_ML_HOL/branches/main/scripts/streamlit/'
MAIN_FILE = 'diamonds_pred_app.py'
QUERY_WAREHOUSE = 'ML_HOL_WH'
TITLE = 'ML_HOL_STREAMLIT_APP'
COMMENT = '{"origin": "sf_sit-is", "name": "e2e_ml_snowparkpython", "version": {"major": 1, "minor": 0}, "attributes": {"is_quickstart": 1, "source": "streamlit"}}';

ALTER STREAMLIT ML_HOL_STREAMLIT_APP ADD LIVE VERSION FROM LAST;
