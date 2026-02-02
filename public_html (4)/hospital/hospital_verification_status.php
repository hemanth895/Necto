 <?php
ini_set('display_errors', 0);
error_reporting(E_ALL);

session_start();
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= AUTH ================= */
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'hospital') {
    header("Location: /login.php");
    exit;
}

$user_id = $_SESSION['user_id'];

/* ================= FETCH PROFILE ================= */
$stmt = $conn->prepare("
    SELECT 
        hospital_name,
        address,
        telephone,
        contact_number,
        pincode,
        hospital_image,
        verified
    FROM hospital_profiles
    WHERE user_id = ?
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$profile = $stmt->get_result()->fetch_assoc();

if (!$profile) {
    die("Profile not found. Complete hospital profile first.");
}

/* ================= SAFE OUTPUT ================= */
function out($val) {
    return htmlspecialchars($val ?? '-', ENT_QUOTES, 'UTF-8');
}

/* ================= HANDLE RE-SUBMIT ================= */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['submit_verification'])) {
    if (!in_array($profile['verified'], ['pending', 'rejected'])) {
        die("Invalid verification state.");
    }
    header("Location: hospital_verification_status.php?submitted=1");
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Verification Status | Necto</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
body {
    margin: 0;
    padding: 0;
    font-family: Arial, sans-serif;
    background: linear-gradient(135deg, #0f766e, #0891b2);
}

/* CARD */
.container {
    max-width: 460px;
    margin: 30px auto;
    background: #ffffff;
    padding: 20px;
    border-radius: 12px;
    box-shadow: 0 6px 18px rgba(0,0,0,0.18);
}

/* HEADER */
.header {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 15px;
}

.back-btn {
    text-decoration: none;
    background: #e9ecef;
    color: #333;
    padding: 6px 10px;
    border-radius: 6px;
    font-size: 13px;
}

/* ROWS – GRID */
.row {
    display: grid;
    grid-template-columns: 160px 1fr;
    gap: 10px;
    padding: 8px 0;
    border-bottom: 1px solid #eee;
}

.label {
    font-weight: 600;
    font-size: 14px;
    color: #444;
}

.value {
    font-size: 14px;
    color: #000;
    word-break: break-word;
}

/* STATUS BADGE */
.status {
    display: inline-block;
    padding: 5px 12px;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 600;
}

.pending { background: #fff3cd; color: #856404; }
.verified { background: #d4edda; color: #155724; }
.rejected { background: #f8d7da; color: #721c24; }

/* BUTTON */
button {
    width: 100%;
    margin-top: 15px;
    padding: 12px;
    font-size: 15px;
    border: none;
    border-radius: 8px;
    background: #0d6efd;
    color: #fff;
}

button:disabled {
    background: #bbb;
}

/* ALERT */
.alert {
    background: #d4edda;
    color: #155724;
    padding: 10px;
    border-radius: 6px;
    margin-bottom: 12px;
    font-size: 14px;
}

/* IMAGE */
.hospital-img {
    width: 100%;
    border-radius: 8px;
    margin-top: 8px;
}

/* MOBILE */
@media (max-width: 600px) {
    .container {
        margin: 12px;
        padding: 16px;
    }

    .row {
        grid-template-columns: 1fr;
    }

    .label {
        font-size: 13px;
        color: #666;
    }
}
</style>
</head>

<body>

<div class="container">

    <div class="header">
        <a href="/hospital/dashboard_hospital.php" class="back-btn">← Back</a>
        <h3>🔐 Verification Status</h3>
    </div>

    <?php if (isset($_GET['submitted'])): ?>
        <div class="alert">
            ✅ Profile submitted for verification. Admin will review shortly.
        </div>
    <?php endif; ?>

    <div class="row"><div class="label">Hospital Name</div><div class="value"><?= out($profile['hospital_name']) ?></div></div>
    <div class="row"><div class="label">Address</div><div class="value"><?= out($profile['address']) ?></div></div>
    <div class="row"><div class="label">Telephone</div><div class="value"><?= out($profile['telephone']) ?></div></div>
    <div class="row"><div class="label">Contact Number</div><div class="value"><?= out($profile['contact_number']) ?></div></div>
    <div class="row"><div class="label">Pincode</div><div class="value"><?= out($profile['pincode']) ?></div></div>

    <div class="row">
        <div class="label">Hospital Image</div>
        <div class="value">
            <?php if ($profile['hospital_image']): ?>
                <img src="<?= out($profile['hospital_image']) ?>" class="hospital-img">
            <?php else: ?>
                -
            <?php endif; ?>
        </div>
    </div>

    <div class="row">
        <div class="label">Verification Status</div>
        <div class="value">
            <?php if ($profile['verified'] === 'pending'): ?>
                <span class="status pending">⏳ Pending</span>
            <?php elseif ($profile['verified'] === 'yes'): ?>
                <span class="status verified">✅ Verified</span>
            <?php else: ?>
                <span class="status rejected">❌ Rejected</span>
            <?php endif; ?>
        </div>
    </div>

    <?php if ($profile['verified'] === 'rejected'): ?>
        <form method="POST">
            <button type="submit" name="submit_verification">
                Re-submit for Verification
            </button>
        </form>
    <?php elseif ($profile['verified'] === 'pending'): ?>
        <button disabled>Verification Pending</button>
    <?php endif; ?>

</div>

</body>
</html>

