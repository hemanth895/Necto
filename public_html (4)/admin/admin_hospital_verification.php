 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= AUTH ================= */
requireLogin();
requireRole("admin");

/* ================= FETCH PENDING HOSPITALS ================= */
$result = $conn->query("
    SELECT 
        hp.id,
        hp.hospital_name,
        hp.telephone,
        hp.contact_number,
        hp.created_at,
        u.email
    FROM hospital_profiles hp
    JOIN users u ON u.id = hp.user_id
    WHERE hp.verified = 'pending'
    ORDER BY hp.created_at DESC
");

/* ================= SAFETY ================= */
if (!$result) {
    die("SQL ERROR: " . $conn->error);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Hospital Verification | Admin</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="/assets/css/dashboard.css">
</head>

<body>

<!-- ================= NAVBAR ================= -->
<div class="navbar">
    <div class="brand">Necto Admin</div>
    <div class="menu">
        <a href="admin_dashboard.php">Dashboard</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<!-- ================= CONTENT ================= -->
<div class="dashboard-wrapper">
<div class="card" style="max-width:1100px;">

<h2>Pending Hospital Verifications</h2>

<?php if ($result->num_rows === 0): ?>
    <p>No pending hospitals 🎉</p>
<?php else: ?>

<table width="100%" cellpadding="12">
<thead>
<tr>
    <th>Hospital</th>
    <th>Email</th>
    <th>Telephone</th>
    <th>Contact Number</th>
    <th>Submitted</th>
    <th>Action</th>
</tr>
</thead>

<tbody>
<?php while ($row = $result->fetch_assoc()): ?>
<tr>
    <td><?= htmlspecialchars($row['hospital_name']) ?></td>
    <td><?= htmlspecialchars($row['email']) ?></td>
    <td><?= htmlspecialchars($row['telephone']) ?></td>
    <td><?= htmlspecialchars($row['contact_number']) ?></td>
    <td><?= date("d M Y", strtotime($row['created_at'])) ?></td>
    <td>
        <a href="admin_hospital_view.php?id=<?= (int)$row['id'] ?>"
           style="color:#2563eb;font-weight:600;">
            Review →
        </a>
    </td>
</tr>
<?php endwhile; ?>
</tbody>

</table>

<?php endif; ?>

</div>
</div>

</body>
</html>
