# OpenFIGI API Java Example


A simple example of using OpenFIGI API with Java.


Dependencies
 - [Jackson](https://github.com/FasterXML/jackson) to serialize/desirialize JSON.


With [Gradle](https://gradle.org)

```
gradle init --type java-application
cp src/build.gradle .
cp src/Example.java ./src/main/java/
rm ./src/main/java/App.java

./gradlew build
./gradlew run
```
