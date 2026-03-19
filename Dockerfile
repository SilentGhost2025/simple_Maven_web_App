#FROM tomcat:9-jdk8
# Dummy text to test 
#COPY target/maven-web-application*.war /usr/local/tomcat/webapps
#FROM tomcat:10-jdk21

FROM tomcat:10-jdk21

# Remove default Tomcat webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy .war into Tomcat
COPY *.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
