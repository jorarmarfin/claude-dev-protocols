; ==========================================================================
; php.ini local — {{PROJECT_NAME}}
; Ajusta estos límites si el sitio real (producción) usa otros distintos.
; ==========================================================================
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_vars = 5000

display_errors = Off
log_errors = On
error_log = /proc/self/fd/2

opcache.enable = 1
opcache.validate_timestamps = 1
opcache.revalidate_freq = 0
