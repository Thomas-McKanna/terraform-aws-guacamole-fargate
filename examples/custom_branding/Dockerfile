# Use the existing guacamole/guacamole image as the base
FROM guacamole/guacamole:1.5.5

# Set the GUACAMOLE_HOME environment variable
ENV GUACAMOLE_HOME=/opt/guacamole

# Copy existing branding extension
COPY branding.jar /opt/guacamole/extensions/branding.jar
