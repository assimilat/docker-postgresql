#!/usr/bin/env bash

exec psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOS
CREATE EXTENSION pgcrypto;
CREATE EXTENSION intarray;

EOS
