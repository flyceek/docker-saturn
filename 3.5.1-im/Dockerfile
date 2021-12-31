FROM openjdk:8-jdk-alpine
LABEL maintainer="flyceek@gmail.com"

COPY build.sh /build.sh

RUN ["sh","/build.sh","alpine","3.5.1","IM"]

EXPOSE 9088