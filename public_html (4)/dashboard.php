 <?php
session_start();
require_once  $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";

// Block if not logged in
if (!isset($_SESSION['user_id'])) {
    header("Location: login.php");
    exit;
}

$user_id = $_SESSION['user_id'];

// Get role
$stmt = $conn->prepare("SELECT role FROM users WHERE id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows !== 1) {
    session_destroy();
    header("Location: login.php");
    exit;
}

$user = $result->fetch_assoc();

// Route by role
if ($user['role'] === 'hospital') {
    header("Location: dashboard_hospital.php");
    exit;
} elseif ($user['role'] === 'staff') {
    header("Location: dashboard_staff.php");
    exit;
} else {
    session_destroy();
    header("Location: login.php");
    exit;
}
