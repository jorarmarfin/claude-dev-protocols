image: atlassian/default-image:4

pipelines:
  branches:
    main:
      - step:
          name: Deploy a producción
          deployment: production
          script:
            - pipe: atlassian/ssh-run:0.8.1
              variables:
                SSH_USER: $DEPLOY_USER
                SERVER: $DEPLOY_HOST
                SSH_KEY: $DEPLOY_SSH_KEY
                MODE: 'command'
                COMMAND: >
                  cd $DEPLOY_PATH &&
                  git pull origin main &&
                  docker compose pull &&
                  docker compose up -d --remove-orphans

# Variables requeridas en Repository settings > Repository variables:
#   DEPLOY_USER, DEPLOY_HOST, DEPLOY_SSH_KEY (secured), DEPLOY_PATH
#
# Post-deploy según el stack (ejecutar en un step aparte o agregar al COMMAND):
#   Drupal:    docker compose exec -T php drush updb -y && drush cr
#   Laravel:   docker compose exec -T php php artisan migrate --force
#   WordPress: docker compose exec -T php wp core update-db
#   Moodle:    docker compose exec -T php php admin/cli/upgrade.php --non-interactive
