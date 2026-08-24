#!/bin/sh
set -e

php artisan reverb:start --host=0.0.0.0 --port=${PORT:-10000}