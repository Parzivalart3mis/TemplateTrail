#!/bin/bash
set -e

# PostgreSQL Initialization Script for N8N Email Automation
# This script runs when the PostgreSQL container is first created

echo "Starting PostgreSQL initialization for N8N..."

# Function to create user and database
create_user_and_db() {
	local database=$1
	local user=$2
	local password=$3

	echo "Creating user '$user' and database '$database'..."

	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		-- Create user if it doesn't exist
		DO \$\$
		BEGIN
		   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$user') THEN
		      CREATE USER $user WITH PASSWORD '$password';
		   END IF;
		END
		\$\$;

		-- Create database if it doesn't exist
		SELECT 'CREATE DATABASE $database OWNER $user'
		WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$database')\gexec

		-- Grant privileges
		GRANT ALL PRIVILEGES ON DATABASE $database TO $user;

		-- Connect to the new database and set up schema permissions
		\c $database

		-- Grant schema permissions
		GRANT ALL ON SCHEMA public TO $user;
		GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $user;
		GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $user;

		-- Set default privileges for future objects
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $user;
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $user;
		ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $user;

		-- Ensure the user can create tables and indexes
		ALTER USER $user CREATEDB;

		-- Set timezone
		ALTER DATABASE $database SET timezone TO 'UTC';

		-- Optimize settings for n8n
		ALTER DATABASE $database SET shared_preload_libraries = '';
		ALTER DATABASE $database SET log_statement = 'none';
		ALTER DATABASE $database SET log_min_duration_statement = -1;

	EOSQL

	echo "Database '$database' and user '$user' created successfully."
}

# Main execution
if [ -n "$POSTGRES_NON_ROOT_USER" ] && [ -n "$POSTGRES_NON_ROOT_PASSWORD" ]; then
	create_user_and_db "$POSTGRES_DB" "$POSTGRES_NON_ROOT_USER" "$POSTGRES_NON_ROOT_PASSWORD"
else
	echo "POSTGRES_NON_ROOT_USER and POSTGRES_NON_ROOT_PASSWORD environment variables not set."
	echo "Using default PostgreSQL user configuration."
fi

# Additional optimizations for n8n performance
echo "Applying PostgreSQL optimizations for n8n..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	-- Performance optimizations
	ALTER SYSTEM SET shared_buffers = '256MB';
	ALTER SYSTEM SET effective_cache_size = '1GB';
	ALTER SYSTEM SET maintenance_work_mem = '64MB';
	ALTER SYSTEM SET checkpoint_completion_target = 0.9;
	ALTER SYSTEM SET wal_buffers = '16MB';
	ALTER SYSTEM SET default_statistics_target = 100;
	ALTER SYSTEM SET random_page_cost = 1.1;
	ALTER SYSTEM SET effective_io_concurrency = 200;

	-- Connection and memory settings
	ALTER SYSTEM SET max_connections = '200';
	ALTER SYSTEM SET work_mem = '4MB';

	-- Logging optimizations (reduce logging for better performance)
	ALTER SYSTEM SET log_min_duration_statement = 1000;
	ALTER SYSTEM SET log_checkpoints = off;
	ALTER SYSTEM SET log_connections = off;
	ALTER SYSTEM SET log_disconnections = off;

	-- Reload configuration
	SELECT pg_reload_conf();
EOSQL

echo "PostgreSQL initialization completed successfully!"
echo "Database is ready for N8N Email Automation system."

# Health check function
check_db_health() {
	echo "Performing database health check..."

	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_NON_ROOT_USER" --dbname "$POSTGRES_DB" <<-EOSQL
		-- Test basic connectivity
		SELECT 'Database connection: OK' as status;

		-- Check if we can create and drop a test table
		CREATE TABLE IF NOT EXISTS health_check_test (id SERIAL PRIMARY KEY, created_at TIMESTAMP DEFAULT NOW());
		INSERT INTO health_check_test DEFAULT VALUES;
		SELECT 'Database write: OK' as status FROM health_check_test LIMIT 1;
		DROP TABLE health_check_test;

		-- Show database information
		SELECT
			'Database: ' || current_database() ||
			', User: ' || current_user ||
			', Version: ' || version() as info;
	EOSQL

	echo "Health check completed successfully!"
}

# Run health check if non-root user is configured
if [ -n "$POSTGRES_NON_ROOT_USER" ]; then
	check_db_health
fi

echo "N8N PostgreSQL initialization script finished."
