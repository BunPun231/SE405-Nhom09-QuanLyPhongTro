#!/bin/sh
set -e

wget -qO- http://localhost:8080/actuator/health >/dev/null
