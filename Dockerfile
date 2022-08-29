# Step 1: Build the code using regular maven
FROM maven:3.8.6-jdk-11 as maven
ARG MY_SECRET
COPY pom.xml /home/app/
WORKDIR /home/app
RUN mvn verify -B --fail-never
COPY src /home/app/src
RUN mvn package -Dquarkus.package.type=native-sources -B -e -Dmysecret=${MY_SECRET}

# Stage 2: Build the native image
FROM quay.io/quarkus/ubi-quarkus-mandrel:22.1-java11 AS native-build
COPY --chown=quarkus:quarkus --from=maven /home/app/target/native-sources /build
USER quarkus
WORKDIR /build
RUN native-image $(cat native-image.args) -J-Xmx4g

# Stage 3: Create the docker final image
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.6
WORKDIR /work/
COPY --from=native-build /build/*-runner /work/application
EXPOSE 8080
ENTRYPOINT [ "/work/application" ]
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]