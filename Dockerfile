# Step 1: Build the Maven project
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# Step 2: Create the runtime image
FROM openjdk:17.0.1-jdk-slim
WORKDIR /app
# Note: 'cims' matches the artifactId in your pom.xml
COPY --from=build /app/target/cims-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]