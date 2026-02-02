 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once($_SERVER['DOCUMENT_ROOT'] . "/config/auth.php");
require_once($_SERVER['DOCUMENT_ROOT'] . "/config/db.php");

/* ================= AUTH ================= */
requireLogin();
requireRole("admin");

/* ================= COUNTS ================= */

// Total staff
$staffCount = $conn->query(
    "SELECT COUNT(*) AS total FROM users WHERE role = 'staff'"
)->fetch_assoc()['total'];

// Total hospitals
$hospitalCount = $conn->query(
    "SELECT COUNT(*) AS total FROM users WHERE role = 'hospital'"
)->fetch_assoc()['total'];

// Pending staff verification (FIXED)
$pendingStaff = $conn->query(
    "SELECT COUNT(*) AS total 
     FROM staff_profiles 
     WHERE verified = 'no'"
)->fetch_assoc()['total'];

// Pending hospital verification (FIXED)
$pendingHospital = $conn->query(
    "SELECT COUNT(*) AS total 
     FROM hospital_profiles 
     WHERE verified = 'pending'"
)->fetch_assoc()['total'];
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard | Necto</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <link rel="stylesheet" href="/assets/css/dashboard.css">
</head>

<body>

<!-- ================= NAVBAR ================= -->
<div class="navbar">
    <div class="brand">Necto Admin</div>
    <div class="menu">
        <a href="admin_dashboard.php">Dashboard</a>
        <a href="admin_staff_verification.php">Verify Staff</a>
        <a href="admin_hospital_verification.php">Verify Hospitals</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<!-- ================= CONTENT ================= -->
<div class="dashboard-wrapper">
    <div class="card" style="max-width:1000px;">

        <h2>Admin Dashboard</h2>
        <p style="margin-bottom:20px;">
            Welcome, Admin. Manage verification and monitor platform activity.
        </p>

        <!-- ================= STATS ================= -->
        <div style="display:flex;gap:20px;flex-wrap:wrap;">

            <div style="flex:1;min-width:200px;background:#ecfeff;padding:20px;border-radius:12px;">
                <h3>Total Staff</h3>
                <p style="font-size:28px;font-weight:bold;">
                    <?= $staffCount ?>
                </p>
            </div>

            <div style="flex:1;min-width:200px;background:#f0fdf4;padding:20px;border-radius:12px;">
                <h3>Total Hospitals</h3>
                <p style="font-size:28px;font-weight:bold;">
                    <?= $hospitalCount ?>
                </p>
            </div>

            <div style="flex:1;min-width:200px;background:#fff7ed;padding:20px;border-radius:12px;">
                <h3>Pending Staff Verification</h3>
                <p style="font-size:28px;font-weight:bold;">
                    <?= $pendingStaff ?>
                </p>
                <a href="admin_staff_verification.php">Review →</a>
            </div>

            <div style="flex:1;min-width:200px;background:#fef2f2;padding:20px;border-radius:12px;">
                <h3>Pending Hospital Verification</h3>
                <p style="font-size:28px;font-weight:bold;">
                    <?= $pendingHospital ?>
                </p>
                <a href="admin_hospital_verification.php">Review →</a>
            </div>

        </div>

    </div>
</div>

</body>
</html>

