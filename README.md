# Career Information Management System (CIMS)

Simple Career Information Management System using Spring Boot (Java) backend and static HTML/CSS frontend.

## Run (Windows)

1. Build and run using Maven wrapper (PowerShell):

   ./mvnw spring-boot:run

2. Open http://localhost:8080 in your browser.

## API Endpoints

- GET /api/careers
- GET /api/careers/{id}
- POST /api/careers
- PUT /api/careers/{id}
- DELETE /api/careers/{id}

Sample curl:

curl http://localhost:8080/api/careers

