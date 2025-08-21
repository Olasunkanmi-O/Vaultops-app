# Use official Tomcat image
FROM tomcat:9.0.73-jdk11

# Remove default ROOT webapp
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR built by Maven into Tomcat webapps folder
COPY target/spring-petclinic-2.4.2.war /usr/local/tomcat/webapps/ROOT.war

# Expose port 8080
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
