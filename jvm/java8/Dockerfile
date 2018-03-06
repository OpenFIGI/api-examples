FROM gradle:jdk

RUN mkdir ./example; \
    cd ./example; \
    gradle init --type java-application; \
    rm -rf src/test; \
    rm src/main/java/App.java

COPY ./src/build.gradle ./example/

COPY ./src/Example.java ./example/src/main/java/

WORKDIR ./example

CMD ./gradlew build && ./gradlew run
