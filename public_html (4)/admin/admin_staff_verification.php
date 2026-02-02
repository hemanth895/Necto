 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= AUTH ================= */
requireLogin();
requireRole("admin");

/* ================= SAFE OUTPUT ================= */
function e($v) {
    return htmlspecialchars($v ?? '', ENT_QUOTES, 'UTF-8');
}

/* ================= FETCH UNVERIFIED STAFF ================= */
$sql = "
SELECT 
    sp.id AS profile_id,
    sp.full_name,
    u.email,
    sp.degree
    sp.stream
    sp.experience_years,
    sp.current_institution
FROM staff_profiles sp
JOIN users u ON u.id = sp.user_id
WHERE (sp.verified IS NULL OR sp.verified != 'yes')
ORDER BY sp.id DESC
";

$result = $conn->query($sql);
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Staff Verification | Admin</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="/assets/css/dashboard.css">
</head>

<body>

<!-- NAVBAR -->
<div class="navbar">
    <div class="brand">Necto Admin</div>
    <div class="menu">
        <a href="admin_dashboard.php">Dashboard</a>
        <a href="admin_staff_verification.php">Verify Staff</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<!-- CONTENT -->
<div class="dashboard-wrapper">
<div class="card" style="max-width:1200px;">

<h2>Pending Staff Verification</h2>

<?php if ($result->num_rows === 0): ?>
    <p>✅ No staff pending verification.</p>
<?php else: ?>

<table width="100%" cellpadding="12">
<tr style="background:#f1f5f9;">
    <th>Name</th>
    <th>Email</th>
    <th>Qualification</th>
    <th>Experience</th>
    <th>Institution</th>
    <th>Action</th>
</tr>

<?php while ($row = $result->fetch_assoc()): ?>
<tr style="border-bottom:1px solid #e5e7eb;">
    <td><?= e($row['full_name']) ?></td>
    <td><?= e($row['email']) ?></td>
    <td><?= e($row['qualification']) ?></td>
    <td><?= (int)$row['experience_years'] ?> yrs</td>
    <td><?= e($row['current_institution']) ?></td>
    <td>
        <a href="admin_staff_view.php?id=<?= (int)$row['profile_id'] ?>">
            View Full Profile →
        </a>
    </td>
</tr>
<?php endwhile; ?>

</table>
<?php endif; ?>

</div>
</div>

</body>
</html>
>
