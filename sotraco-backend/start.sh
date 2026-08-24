#!/bin/sh
set -e

# Si on utilise SQLite (dev/fallback) et que le fichier n'existe pas encore, le créer.
if [ "$DB_CONNECTION" = "sqlite" ] && [ ! -f "database/databasesotraco.sqlite" ]; then
    touch database/databasesotraco.sqlite
fi

# Applique les migrations en attente sans jamais effacer les données existantes.
php artisan migrate --force

# Met en cache la config maintenant (au démarrage, une fois les vraies
# variables d'environnement Render disponibles — jamais pendant le build).
php artisan config:cache

php artisan serve --host=0.0.0.0 --port=${PORT:-10000}