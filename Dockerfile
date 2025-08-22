# Use an official Tomcat base image
FROM tomcat:9.0-jdk17

# Maintainer label
LABEL maintainer="ola.m.owolabi@outlook.com"

# Remove default ROOT webapp
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR built by Maven into the Tomcat webapps directory
COPY target/spring-petclinic-2.4.2.war /usr/local/tomcat/webapps/ROOT.war

# Expose the port Tomcat runs on
EXPOSE 8080

# Environment variables for Spring Boot (to be injected at runtime)
ENV SPRING_DATASOURCE_URL=
ENV SPRING_DATASOURCE_USERNAME=
ENV SPRING_DATASOURCE_PASSWORD=
ENV SPRING_PROFILES_ACTIVE=

# Start Tomcat
CMD ["catalina.sh", "run"]
