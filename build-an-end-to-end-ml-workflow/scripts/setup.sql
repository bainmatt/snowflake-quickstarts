-- Using ACCOUNTADMIN, create a new role for this demo
USE ROLE ACCOUNTADMIN;
SET USERNAME = (SELECT CURRENT_USER());
SELECT $USERNAME;
CREATE ROLE IF NOT EXISTS E2E_SNOW_MLOPS_ROLE;

-- Grant permissions to new role to create:
-- databases, compute pools, service endpoints
GRANT CREATE DATABASE on ACCOUNT to ROLE E2E_SNOW_MLOPS_ROLE;
GRANT CREATE WAREHOUSE ON ACCOUNT to ROLE E2E_SNOW_MLOPS_ROLE;
GRANT BIND SERVICE ENDPOINT on ACCOUNT to ROLE E2E_SNOW_MLOPS_ROLE;
GRANT CREATE INTEGRATION on ACCOUNT to ROLE E2E_SNOW_MLOPS_ROLE;

-- Grant new role to user and switch to that role
GRANT ROLE E2E_SNOW_MLOPS_ROLE to USER identifier($USERNAME);
USE ROLE E2E_SNOW_MLOPS_ROLE;

-- Create warehouse
CREATE OR REPLACE WAREHOUSE E2E_SNOW_MLOPS_WH WITH WAREHOUSE_SIZE='MEDIUM';

-- Create database
CREATE OR REPLACE DATABASE E2E_SNOW_MLOPS_DB;
USE DATABASE E2E_SNOW_MLOPS_DB;

-- Create schema
CREATE OR REPLACE SCHEMA MLOPS_SCHEMA;
USE SCHEMA MLOPS_SCHEMA;

-- PyPI integration ----------------------------------------------------------

-- Create network rule and API integration to install packages from PyPI
-- [MB] NOTE: External access not supported for trial account.
-- Disable all queries targeting this network rule.
CREATE OR REPLACE NETWORK RULE mlops_pypi_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = (
    'pypi.org',
    'pypi.python.org',
    'pythonhosted.org',
    'files.pythonhosted.org'
  );

-- [MB] NOTE: External access not supported for trial account.
-- Create external access integration on top of network rule for PyPI access
-- CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION mlops_pypi_access_integration
--   ALLOWED_NETWORK_RULES = (mlops_pypi_network_rule)
--   ENABLED = true;

-- GitHub integration --------------------------------------------------------

-- Note: The following steps pull files directly from the Snowflake Labs
-- repo into your Snowflake account. You can run them as Snowflake-hosted
-- notebooks and Streamlit apps.
--
-- If you prefer to work locally (using this cloned repo in Jupyter/VSCode),
-- you can safely skip these steps.

-- Create an API integration with GitHub
-- [MB] NOTE: External access not supported for trial account.
-- Disable all queries targeting this network rule.
-- This also applies to PyPI integration.
CREATE OR REPLACE API INTEGRATION GITHUB_INTEGRATION_E2E_SNOW_MLOPS
  api_provider = git_https_api
  api_allowed_prefixes = ('https://github.com/Snowflake-Labs')
  enabled = true
  comment = 'Git integration with Snowflake Demo GitHub Repository.';

-- Create the integration with the GitHub demo repository
CREATE OR REPLACE GIT REPOSITORY GITHUB_REPO_E2E_SNOW_MLOPS
  ORIGIN = 'https://github.com/Snowflake-Labs/sfguide-build-end-to-end-ml-workflow-in-snowflake'
  API_INTEGRATION = 'GITHUB_INTEGRATION_E2E_SNOW_MLOPS'
  COMMENT = 'GitHub Repository ';

-- Fetch most recent files from GitHub repository
ALTER GIT REPOSITORY GITHUB_REPO_E2E_SNOW_MLOPS FETCH;

-- Copy notebook into snowflake & configure runtime settings
CREATE OR REPLACE NOTEBOOK E2E_SNOW_MLOPS_DB.MLOPS_SCHEMA.TRAIN_DEPLOY_MONITOR_ML
FROM '@E2E_SNOW_MLOPS_DB.MLOPS_SCHEMA.GITHUB_REPO_E2E_SNOW_MLOPS/branches/main/'
MAIN_FILE = 'train_deploy_monitor_ML_in_snowflake.ipynb'
QUERY_WAREHOUSE = E2E_SNOW_MLOPS_WH
RUNTIME_NAME = 'SYSTEM$BASIC_RUNTIME'
COMPUTE_POOL = 'SYSTEM_COMPUTE_POOL_CPU'
IDLE_AUTO_SHUTDOWN_TIME_SECONDS = 3600;

-- [MB] NOTE: External access not supported for trial account.
-- ALTER NOTEBOOK E2E_SNOW_MLOPS_DB.MLOPS_SCHEMA.TRAIN_DEPLOY_MONITOR_ML
-- SET EXTERNAL_ACCESS_INTEGRATIONS = ( 'mlops_pypi_access_integration' );

-- DONE! Now you can access your newly created notebook with your
-- E2E_SNOW_MLOPS_ROLE and run through the end-to-end workflow!

SHOW NOTEBOOKS;

GRANT USAGE ON DATABASE E2E_SNOW_MLOPS_DB to ROLE ACCOUNTADMIN;
GRANT USAGE ON SCHEMA MLOPS_SCHEMA to ROLE ACCOUNTADMIN;
