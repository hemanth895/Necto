 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";

/* ================= AUTH HELPERS ================= */
requireLogin();
requireRole('staff');

/* ================= AUTH CHECK ================= */
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'staff') {
    header("Location: /login.php");
    exit;
}

$user_id = $_SESSION['user_id'];

/* ================= FETCH USER NAME ================= */
$nameStmt = $conn->prepare("SELECT name FROM users WHERE id = ?");
$nameStmt->bind_param("i", $user_id);
$nameStmt->execute();
$nameRow = $nameStmt->get_result()->fetch_assoc();
$displayName = $nameRow ? $nameRow['name'] : 'Account';

/* ================= FETCH STAFF PROFILE ================= */
$profileStmt = $conn->prepare(
    "SELECT verified, rejection_reason 
     FROM staff_profiles 
     WHERE user_id = ?"
);
$profileStmt->bind_param("i", $user_id);
$profileStmt->execute();
$profileResult = $profileStmt->get_result();

$hasProfile = false;
$isVerified = false;
$rejectionReason = null;

if ($profileResult->num_rows === 1) {
    $hasProfile = true;
    $profileRow = $profileResult->fetch_assoc();
    $isVerified = ($profileRow['verified'] === 'yes');
    $rejectionReason = $profileRow['rejection_reason'];
}

/* ================= CHECK ACTIVE AVAILABILITY ================= */
$availabilityStmt = $conn->prepare("
    SELECT id FROM staff_availability
    WHERE staff_id = ? AND status = 'available'
    LIMIT 1
");
$availabilityStmt->bind_param("i", $user_id);
$availabilityStmt->execute();
$hasActiveAvailability = ($availabilityStmt->get_result()->num_rows === 1);

/* ================= FETCH DASHBOARD NOTIFICATION ================= */
$notifStmt = $conn->prepare(
    "SELECT id, title, message 
     FROM staff_notifications
     WHERE staff_id = ? AND is_read = 'no'
     ORDER BY created_at DESC
     LIMIT 1"
);
$notifStmt->bind_param("i", $user_id);
$notifStmt->execute();
$notification = $notifStmt->get_result()->fetch_assoc();

/* ================= MARK NOTIFICATION READ ================= */
if ($notification) {
    $markStmt = $conn->prepare(
        "UPDATE staff_notifications SET is_read='yes' WHERE id=?"
    );
    $markStmt->bind_param("i", $notification['id']);
    $markStmt->execute();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Staff Dashboard | Necto</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="stylesheet" href="/assets/css/dashboard.css">
<link rel="stylesheet" href="/assets/css/staff.css">
</head>

<body>

<!-- ================= NAVBAR ================= -->
<div class="navbar">
    <div class="brand">Necto</div>
    <div class="menu">
        <a href="dashboard_staff.php">Home</a>

        <?php if (!$hasProfile): ?>
            <a href="staff_profile.php">Create Profile</a>

        <?php elseif ($isVerified && !$hasActiveAvailability): ?>
            <span style="color:#86efac;font-weight:600;">✔ Verified</span>
            <a href="staff_post_availability.php">Post Availability</a>

        <?php elseif ($isVerified && $hasActiveAvailability): ?>
            <span style="color:#86efac;font-weight:600;">✔ Verified</span>

        <?php else: ?>
            <span style="color:#fde68a;font-weight:600;">⏳ Verification Pending</span>
        <?php endif; ?>

        <a href="/index.php">About Necto</a>

        <a href="staff_account.php" style="font-weight:600;color:#e6fffa;">
            <?= htmlspecialchars($displayName) ?>
        </a>

        <a href="/logout.php">Logout</a>
    </div>
</div>

<!-- ================= DASHBOARD CONTENT ================= -->
<div class="dashboard-wrapper">
<div class="card">

<?php if (isset($_GET['availability']) && $_GET['availability'] === 'created'): ?>
<div style="background:#dcfce7;color:#166534;padding:16px;border-radius:10px;margin-bottom:16px;font-weight:500;">
    ✅ Availability successfully created. Hospitals will get back to you.
</div>
<?php endif; ?>

<!-- ================= NOTIFICATION ================= -->
<?php if ($notification): ?>
<div style="background:#dcfce7;color:#166534;padding:16px;border-radius:10px;margin-bottom:16px;">
    🔔 <strong><?= htmlspecialchars($notification['title']) ?></strong><br>
    <?= htmlspecialchars($notification['message']) ?>
</div>
<?php endif; ?>

<!-- ================= NO PROFILE ================= -->
<?php if (!$hasProfile): ?>

<h2>Complete Your Profile</h2>
<p>You must create your staff profile before proceeding.</p>
<a href="staff_profile.php" class="btn">Create Profile</a>

<!-- ================= PROFILE REJECTED ================= -->
<?php elseif (!$isVerified && $rejectionReason): ?>

<div style="background:#fee2e2;color:#991b1b;padding:16px;border-radius:10px;">
    ❌ <strong>Profile Rejected</strong><br><br>
    <strong>Reason:</strong> <?= htmlspecialchars($rejectionReason) ?><br><br>
    <a href="staff_profile.php?edit=1" style="font-weight:bold;color:#7c2d12;">
        ✏️ Edit Profile & Resubmit →
    </a>
</div>

<!-- ================= PROFILE PENDING ================= -->
<?php elseif (!$isVerified): ?>

<h2>Verification Pending</h2>
<div style="background:#fff3cd;padding:16px;border-radius:8px;color:#92400e;">
    Your profile has been submitted and is awaiting admin verification.<br><br>
    <strong>Status:</strong> Pending
</div>

<!-- ================= PROFILE VERIFIED ================= -->
<?php elseif ($isVerified): ?>

<div style="background:#dcfce7;padding:16px;border-radius:8px;color:#166534;margin-bottom:16px;">
    🎉 <strong>Verification Completed!</strong><br>
    You can now post your availability for hospitals.
</div>

<?php if (!$hasActiveAvailability): ?>
    <a href="staff_post_availability.php" class="btn">
        ➕ Create Availability Post
    </a>
<?php else: ?>
    <div style="background:#e0f2fe;padding:14px;border-radius:8px;color:#075985;">
        📌 <strong>Availability Active</strong><br>
        Hospitals can now view your profile and contact you.
    </div>
<?php endif; ?>

<?php endif; ?>

</div>
</div>

</body>
</html>


