FROM quay.io/quarkus/ubi-quarkus-mandrel-builder-image:22.3-java17 AS native-build
ARG MY_SECRET
COPY --chown=quarkus:quarkus mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
COPY --chown=quarkus:quarkus pom.xml /code/
USER root
RUN chown -R quarkus:quarkus /code
USER quarkus
WORKDIR /code
RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.1.2:go-offline
COPY src /code/src
RUN ./mvnw package -e -Dnative -Dmysecret=${MY_SECRET}

# Stage 2: Create the docker final image
FROM quay.io/quarkus/quarkus-micro-image:2.0
WORKDIR /work/
COPY --from=native-build /code/target/*-runner /work/application
RUN chmod 775 /work
EXPOSE 8080
ENTRYPOINT [ "/work/application" ]
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]