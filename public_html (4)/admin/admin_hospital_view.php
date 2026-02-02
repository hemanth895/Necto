 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT']."/config/auth.php";
require_once $_SERVER['DOCUMENT_ROOT']."/config/db.php";

requireLogin();
requireRole("admin");

// Validate ID
if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    die("Invalid request");
}

$id = (int)$_GET['id'];

// Fetch hospital profile
$stmt = $conn->prepare("
    SELECT hp.*, u.email AS user_email
    FROM hospital_profiles hp
    JOIN users u ON u.id = hp.user_id
    WHERE hp.id = ?
");
$stmt->bind_param("i", $id);
$stmt->execute();
$hp = $stmt->get_result()->fetch_assoc();

if (!$hp) {
    die("Hospital not found");
}

// ================= APPROVE =================
if (isset($_POST['approve'])) {

    $conn->query("
        UPDATE hospital_profiles 
        SET verified='yes'
        WHERE id=$id
    ");

    // Dashboard notification
    $n = $conn->prepare("
        INSERT INTO hospital_notifications (hospital_id, title, message)
        VALUES (?, ?, ?)
    ");
    $title = "Hospital Verified";
    $msg = "Your hospital profile is verified. You can now post shifts.";
    $n->bind_param("iss", $hp['user_id'], $title, $msg);
    $n->execute();

    header("Location: admin_hospital_verification.php?approved=1");
    exit;
}

// ================= REJECT =================
if (isset($_POST['reject'])) {

    $reason = trim($_POST['reason']);

    if ($reason === "") {
        die("Rejection reason required");
    }

    $stmt = $conn->prepare("
        UPDATE hospital_profiles 
        SET verified='no'
        WHERE id=?
    ");
    $stmt->bind_param("i", $id);
    $stmt->execute();

    // Dashboard notification
    $n = $conn->prepare("
        INSERT INTO hospital_notifications (hospital_id, title, message)
        VALUES (?, ?, ?)
    ");
    $title = "Hospital Profile Rejected";
    $msg = "Your hospital profile was rejected. Reason: ".$reason;
    $n->bind_param("iss", $hp['user_id'], $title, $msg);
    $n->execute();

    header("Location: admin_hospital_verification.php?rejected=1");
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Review Hospital | Admin</title>
<link rel="stylesheet" href="/assets/css/dashboard.css">
</head>
<body>

<div class="navbar">
    <div class="brand">Necto Admin</div>
    <div class="menu">
        <a href="admin_hospital_verification.php">← Back</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<div class="dashboard-wrapper">
<div class="card" style="max-width:900px">

<h2>Hospital Profile Review</h2>

<p><b>Name:</b> <?= htmlspecialchars($hp['hospital_name']) ?></p>
<p><b>Email:</b> <?= htmlspecialchars($hp['user_email']) ?></p>
<p><b>Telephone:</b> <?= htmlspecialchars($hp['telephone']) ?></p>
<p><b>Contact Number:</b> <?= htmlspecialchars($hp['contact_number']) ?></p>
<p><b>Address:</b><br><?= nl2br(htmlspecialchars($hp['address'])) ?></p>

<?php if (!empty($hp['hospital_image'])): ?>
<p>
<b>Hospital Image:</b><br>
<img src="<?= htmlspecialchars($hp['hospital_image']) ?>" 
     style="max-width:250px;border-radius:12px;">
</p>
<?php endif; ?>

<hr>

<form method="post" style="display:flex;gap:20px">

<button name="approve" style="
background:#16a34a;color:#fff;padding:14px 22px;
border:none;border-radius:10px;font-size:16px">
✅ Verify Hospital
</button>

</form>

<hr>

<form method="post">
<textarea name="reason" placeholder="Reason for rejection" required
style="width:100%;padding:12px;border-radius:8px"></textarea><br><br>

<button name="reject" style="
background:#dc2626;color:#fff;padding:14px 22px;
border:none;border-radius:10px;font-size:16px">
❌ Reject Hospital
</button>
</form>

</div>
</div>
</body>
</html>
