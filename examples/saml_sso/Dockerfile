# Use the existing guacamole/guacamole image as the base
FROM guacamole/guacamole:1.5.5

# Set the GUACAMOLE_HOME environment variable
ENV GUACAMOLE_HOME=/opt/guacamole

COPY guacamole-auth-sso-saml-1.5.5.jar /opt/guacamole/extensions/guacamole-auth-sso-saml-1.5.5.jar

USER root

# Append SAML configuration to guacamole.properties
RUN echo "\
# SAML Authentication Configuration\n\
saml-idp-metadata-url: CHANGEME\n\
saml-entity-id: https://CHANGEME/guacamole/\n\
saml-callback-url: https://CHANGEME/guacamole/\n\
# Will be different per IdP. This example is from Entra ID\n\
saml-group-attribute: http://schemas.microsoft.com/ws/2008/06/identity/claims/groups\n\
saml-strict: false\n\
saml-debug: false\n\
saml-compress-request: true\n\
saml-compress-response: true\n\
\n\
\n\
# Extension priority to prioritize SAML over JDBC\n\
extension-priority: *, saml\n\
" >> /opt/guacamole/guacamole.properties

USER guacamole
