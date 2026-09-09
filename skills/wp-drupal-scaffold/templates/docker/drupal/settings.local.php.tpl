<?php

/**
 * settings.local.php — {{PROJECT_NAME}}
 * Incluido desde sites/default/settings.php con:
 *
 *   if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
 *     include $app_root . '/' . $site_path . '/settings.local.php';
 *   }
 *
 * Este archivo vive en docker/drupal/ y sí se versiona; el settings.php
 * real del código no se toca.
 */

$databases['default']['default'] = [
    'database' => getenv('DB_NAME'),
    'username' => getenv('DB_USER'),
    'password' => getenv('DB_PASSWORD'),
    'host'     => getenv('DB_HOST'),
    'port'     => getenv('DB_PORT'),
    'driver'   => 'mysql',
    'prefix'   => '',
];

$settings['trusted_host_patterns'] = [
    '^' . preg_quote(getenv('LOCAL_DOMAIN'), '/') . '$',
];

$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

$settings['config_sync_directory'] = '../config/sync';
