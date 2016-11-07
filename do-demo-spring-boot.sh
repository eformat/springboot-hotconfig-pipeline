#!/usr/bin/env bash

if [ ! -d .git ]; then
    git init
    git add .
    git commit -m 'initial commit'
else
    git add .
fi

echo 'spring.application.name=helloservice' > src/main/resources/application.properties

rm -fr src/test/

cat <<'EOF' > pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>demo</name>
    <description>Demo project for Spring Boot</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.4.1.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <java.version>1.8</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <fabric8.version>2.2.170</fabric8.version>
        <spring-boot.version>1.4.1.RELEASE</spring-boot.version>
        <spring-cloud-kubernetes.version>0.1.3</spring-cloud-kubernetes.version>
        <fabric8.maven.plugin.version>3.1.79</fabric8.maven.plugin.version>
        <maven-compiler-plugin.version>3.5.1</maven-compiler-plugin.version>
        <maven-surefire-plugin.version>2.18.1</maven-surefire-plugin.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>io.fabric8</groupId>
                <artifactId>fabric8-project-bom-camel-spring-boot</artifactId>
                <version>${fabric8.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>

            <dependency>
                <groupId>io.fabric8</groupId>
                <artifactId>spring-cloud-kubernetes-core</artifactId>
                <version>${spring-cloud-kubernetes.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.apache.camel</groupId>
            <artifactId>camel-spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>io.fabric8</groupId>
            <artifactId>spring-cloud-kubernetes-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>${maven-compiler-plugin.version}</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>${maven-surefire-plugin.version}</version>
                <inherited>true</inherited>
                <configuration>
                    <excludes>
                        <exclude>**/*KT.java</exclude>
                    </excludes>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>io.fabric8</groupId>
                <artifactId>fabric8-maven-plugin</artifactId>
                <version>${fabric8.maven.plugin.version}</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>resource</goal>
                            <goal>build</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>

</project>
EOF

cat <<'EOF' > src/main/java/com/example/DemoApplication.java
package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class DemoApplication {
public static void main(String[] args) {
SpringApplication.run(DemoApplication.class, args);
}
}
@RestController()
@RequestMapping("/api")
class HelloController {
    private static int counter = 0;
    @Autowired
    private HelloConfig config;

    @RequestMapping(value = "/hello/{name}", method = RequestMethod.GET)
    public Map<String, Object> hello(@PathVariable String name) throws Exception {
        HashMap<String, Object> response = new HashMap<>();
        response.put("response", config.getMessage());
        response.put("your-name", name);
        response.put("count", counter++);
        return response;
    }
}
EOF

cat <<'EOF' > src/main/java/com/example/HelloConfig.java
package com.example;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "helloservice")
public class HelloConfig {

    private String message;

    public HelloConfig() {
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
EOF

cat <<'EOF' > src/main/resources/application.properties
spring.application.name=helloservice

# Enable auto-reload
spring.cloud.kubernetes.reload.enabled=true

helloservice.message=default hello
EOF

cat <<EOF >> configmap.yml
kind: ConfigMap
apiVersion: v1
metadata:
  name: helloservice
data:
  application.yaml: |-
    helloservice:
      message: hello, spring cloud kubernetes !
EOF
