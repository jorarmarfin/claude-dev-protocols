<?php
/**
 * wp-config.php local — {{PROJECT_NAME}}
 * Montado sobre /var/www/html/wp-config.php. No editar el real del código
 * versionado: este archivo vive en docker/wordpress/ y sí se versiona.
 */

$table_prefix = getenv('TABLE_PREFIX') ?: 'wp_';

define('DB_NAME',     getenv('DB_NAME'));
define('DB_USER',     getenv('DB_USER'));
define('DB_PASSWORD', getenv('DB_PASSWORD'));
define('DB_HOST',     getenv('DB_HOST') . ':' . getenv('DB_PORT'));
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('WP_HOME', getenv('LOCAL_SCHEME') . '://' . getenv('LOCAL_DOMAIN'));
define('WP_SITEURL', WP_HOME);

define('WP_DEBUG', filter_var(getenv('WP_DEBUG'), FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_LOG', filter_var(getenv('WP_DEBUG_LOG'), FILTER_VALIDATE_BOOLEAN));
define('WP_DEBUG_DISPLAY', filter_var(getenv('WP_DEBUG_DISPLAY'), FILTER_VALIDATE_BOOLEAN));

if (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') {
    $_SERVER['HTTPS'] = 'on';
}

// Claves únicas — regenerar para producción real, no importa en local.
define('AUTH_KEY',         'local-only-key-1');
define('SECURE_AUTH_KEY',  'local-only-key-2');
define('LOGGED_IN_KEY',    'local-only-key-3');
define('NONCE_KEY',        'local-only-key-4');
define('AUTH_SALT',        'local-only-salt-1');
define('SECURE_AUTH_SALT', 'local-only-salt-2');
define('LOGGED_IN_SALT',   'local-only-salt-3');
define('NONCE_SALT',       'local-only-salt-4');

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
