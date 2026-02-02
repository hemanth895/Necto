<?php
session_start();
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

if (!isset($_SESSION['user_id'])) exit;

$data = json_decode(file_get_contents("php://input"), true);

$endpoint = $data['endpoint'];
$p256dh   = $data['keys']['p256dh'];
$auth     = $data['keys']['auth'];

$stmt = $conn->prepare("
    INSERT INTO web_push_subscriptions (user_id, endpoint, p256dh, auth)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE endpoint=endpoint
");
$stmt->bind_param("isss", $_SESSION['user_id'], $endpoint, $p256dh, $auth);
$stmt->execute();
