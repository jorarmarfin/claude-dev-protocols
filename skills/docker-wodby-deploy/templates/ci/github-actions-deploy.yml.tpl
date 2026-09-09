name: Deploy

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy por SSH (rsync + docker compose)
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          script: |
            cd ${{ secrets.DEPLOY_PATH }}
            git pull origin main
            docker compose pull
            docker compose up -d --remove-orphans
            # Ajustar el comando de post-deploy según el stack:
            # Drupal:    docker compose exec -T php drush updb -y && drush cr
            # Laravel:   docker compose exec -T php php artisan migrate --force
            # WordPress: docker compose exec -T php wp core update-db
            # Moodle:    docker compose exec -T php php admin/cli/upgrade.php --non-interactive

# Secrets requeridos en el repo (Settings > Secrets and variables > Actions):
#   DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY, DEPLOY_PATH
