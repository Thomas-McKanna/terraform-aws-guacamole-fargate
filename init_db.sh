#!/bin/bash

# This script expects the following environment variables to be set:
#   DB_ARN: The ARN of the database to initialize
#   DB_SECRET_ARN: The ARN of the secret containing the database credentials
#   DB_NAME: The name of the database to initialize
#   GUACADMIN_PASSWORD: The password to set for the guacadmin user

# These values are those found in the official Guacamole initialization script
ORIG_HASH="CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960" # guacadmin
ORIG_SALT="FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264"

# Randomly generate a new salt for the guacadmin password
NEW_SALT=$(openssl rand 32 | sha256sum | awk '{ print toupper($1) }')

# Calculate the new hash for the guacadmin password
NEW_HASH=$(echo -n "${GUACADMIN_PASSWORD}${NEW_SALT}" | sha256sum | awk '{ print toupper($1) }')

# Generate initialization script from latest guacamole image
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > /tmp/initdb.sql

# Replace default guacadmin password with the one provided
sed -i 's/'"$ORIG_HASH"'/'"$NEW_HASH"'/g' /tmp/initdb.sql
sed -i 's/'"$ORIG_SALT"'/'"$NEW_SALT"'/g' /tmp/initdb.sql

# Use Aurora Data API to execute the initialization script
aws rds-data execute-statement \
    --resource-arn "${DB_ARN}" \
    --secret-arn "${DB_SECRET_ARN}" \
    --database "${DB_NAME}" \
    --sql "file:///tmp/initdb.sql"

# Remove the initialization script
rm /tmp/initdb.sql
