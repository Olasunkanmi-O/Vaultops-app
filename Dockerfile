# Use an official java kit
FROM openjdk:11-jdk-slim

# Maintainer label
LABEL maintainer="ola.m.owolabi@outlook.com"

WORKDIR /app

# Copy your WAR
COPY target/spring-petclinic-2.4.2.war .

# Expose the app port 
EXPOSE 8080

# Environment variables for Spring Boot (to be injected at runtime)
ENV SPRING_DATASOURCE_URL=
ENV SPRING_DATASOURCE_USERNAME=
ENV SPRING_DATASOURCE_PASSWORD=
ENV SPRING_PROFILES_ACTIVE=

# Run the WAR using embedded Tomcat
ENTRYPOINT ["java","-jar","/app/spring-petclinic-2.4.2.war"]
