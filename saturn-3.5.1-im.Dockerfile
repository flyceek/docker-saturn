FROM openjdk:8-jdk-alpine
MAINTAINER flyceek@gmail.com

COPY build-v2.sh /build.sh

RUN ["sh","/build.sh","alpine","3.5.1","IM"]

EXPOSE 9088