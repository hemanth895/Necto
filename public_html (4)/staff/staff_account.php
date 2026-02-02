<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";

requireLogin();
requireRole("staff");

$user_id = $_SESSION['user_id'];

$stmt = $conn->prepare(
    "SELECT name, email, role FROM users WHERE id = ?"
);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

if (!$user) {
    die("Account not found");
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>My Account | Necto</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="stylesheet" href="/assets/css/dashboard.css">
<link rel="stylesheet" href="/assets/css/staff.css">
</head>

<body>

<div class="navbar">
    <div class="brand">Necto</div>
    <div class="menu">
        <a href="dashboard_staff.php">Home</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<div class="dashboard-wrapper">
    <div class="card">
        <h2>My Account</h2>

        <p><strong>Name:</strong> <?php echo htmlspecialchars($user['name']); ?></p>
        <p><strong>Email:</strong> <?php echo htmlspecialchars($user['email']); ?></p>
        <p><strong>Role:</strong> <?php echo ucfirst($user['role']); ?></p>
    </div>
</div>

</body>
</html>
