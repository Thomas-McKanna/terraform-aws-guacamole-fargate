# Use the existing guacamole/guacamole image as the base
FROM guacamole/guacamole:1.5.5

# Set the GUACAMOLE_HOME environment variable
ENV GUACAMOLE_HOME=/opt/guacamole

# Copy custom extension
COPY custom.jar /opt/guacamole/extensions/custom.jar
