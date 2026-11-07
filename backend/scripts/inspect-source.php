<?php
// Diagnóstico de solo lectura: reutiliza la configuración sin arrancar Laravel.
require 'D:/ProyectosCODE/rsu_project/vendor/autoload.php';
$env = Dotenv\Dotenv::parse(file_get_contents('D:/ProyectosCODE/rsu_project/.env'));
try {
    $pdo = new PDO("mysql:host={$env['DB_HOST']};port={$env['DB_PORT']};dbname={$env['DB_DATABASE']};charset=utf8mb4", $env['DB_USERNAME'], $env['DB_PASSWORD'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 10,
        PDO::MYSQL_ATTR_SSL_CA => $env['MYSQL_ATTR_SSL_CA'],
        PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => true,
    ]);
    foreach (['employees', 'employee_types', 'programming_schedules', 'vehicles', 'attendances', 'schedule_runs'] as $table) {
        echo $table.': '.$pdo->query("SELECT COUNT(*) FROM `$table`")->fetchColumn().PHP_EOL;
    }
    echo 'TLS: '.$pdo->query("SHOW STATUS LIKE 'Ssl_cipher'")->fetch(PDO::FETCH_NUM)[1].PHP_EOL;
} catch (Throwable $e) {
    fwrite(STDERR, 'No se pudo verificar TiDB: '.$e->getMessage().PHP_EOL);
    exit(1);
}
