FROM postgres:latest

COPY bd_vkr.sql /docker-entrypoint-initdb.d/
COPY data/grls.sql /docker-entrypoint-initdb.d/
COPY data/test_data.sql /docker-entrypoint-initdb.d/

ENV POSTGRES_USER=medtrack
ENV POSTGRES_PASSWORD=medtrack
ENV POSTGRES_DB=medtrack
