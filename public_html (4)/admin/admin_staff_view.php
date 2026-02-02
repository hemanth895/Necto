 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= WEB PUSH ================= */
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/push.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/vendor/autoload.php";

use Minishlink\WebPush\WebPush;
use Minishlink\WebPush\Subscription;

/* ================= AUTH ================= */
requireLogin();
requireRole("admin");

/* ================= SAFE OUTPUT ================= */
function e($v) {
    return htmlspecialchars($v ?? '', ENT_QUOTES, 'UTF-8');
}

/* ================= VALIDATE ID ================= */
if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    die("Invalid request");
}

$id = (int)$_GET['id'];

/* ================= FETCH PROFILE ================= */
$stmt = $conn->prepare("
    SELECT sp.*, u.email 
    FROM staff_profiles sp
    JOIN users u ON u.id = sp.user_id
    WHERE sp.id = ?
");
$stmt->bind_param("i", $id);
$stmt->execute();
$sp = $stmt->get_result()->fetch_assoc();

if (!$sp) {
    die("Staff profile not found");
}

/* ================= HANDLE POST ================= */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    /* ================= HANDLE REJECT ================= */
    if (isset($_POST['reject'])) {

        $reason = trim($_POST['rejection_reason']);

        if ($reason === '') {
            die("Rejection reason is required.");
        }

        // Update rejection
        $stmt = $conn->prepare("
            UPDATE staff_profiles 
            SET verified='no', rejection_reason=?
            WHERE id=?
        ");
        $stmt->bind_param("si", $reason, $id);
        $stmt->execute();

        /* ================= DASHBOARD NOTIFICATION ================= */
        $notifyStmt = $conn->prepare("
            INSERT INTO staff_notifications (staff_id, title, message)
            VALUES (?, ?, ?)
        ");
        $notifyStmt->bind_param(
            "iss",
            $sp['user_id'],
            "Profile Rejected",
            "Your profile was rejected. Reason: $reason"
        );
        $notifyStmt->execute();

        /* ================= WEB PUSH NOTIFICATION ================= */
        $auth = [
            'VAPID' => [
                'subject' => 'mailto:admin@necto.in',
                'publicKey' => VAPID_PUBLIC,
                'privateKey' => VAPID_PRIVATE,
            ],
        ];

        $webPush = new WebPush($auth);

        $subStmt = $conn->prepare("
            SELECT endpoint, p256dh, auth
            FROM web_push_subscriptions
            WHERE user_id = ?
        ");
        $subStmt->bind_param("i", $sp['user_id']);
        $subStmt->execute();
        $subs = $subStmt->get_result();

        while ($row = $subs->fetch_assoc()) {

            $subscription = Subscription::create([
                'endpoint' => $row['endpoint'],
                'keys' => [
                    'p256dh' => $row['p256dh'],
                    'auth' => $row['auth'],
                ],
            ]);

            $payload = json_encode([
                'title' => 'Profile Rejected',
                'body'  => 'Your profile was rejected. Please review and resubmit.'
            ]);

            $webPush->sendOneNotification($subscription, $payload);
        }

        $webPush->flush();

        header("Location: admin_staff_verification.php?rejected=1");
        exit;
    }

    /* ================= HANDLE VERIFY ================= */

    // Update verification
    $conn->query("UPDATE staff_profiles SET verified='yes', rejection_reason=NULL WHERE id=$id");

    /* ================= DASHBOARD NOTIFICATION ================= */

$notifyStmt = $conn->prepare("
    INSERT INTO staff_notifications (staff_id, title, message)
    VALUES (?, ?, ?)
");

$title   = "Profile Verified";
$message = "Your profile has been verified by admin. You can now post your availability.";
$staffId = $sp['user_id'];

$notifyStmt->bind_param(
    "iss",
    $staffId,
    $title,
    $message
);

$notifyStmt->execute();

    

    /* ================= EMAIL NOTIFICATION ================= */
    $to = $sp['email'];
    $name = $sp['full_name'];

    $subject = "Your Necto profile is verified 🎉";
    $message = "
Hi $name,

Good news!

Your staff profile on Necto has been successfully verified.

You can now:
• Log in to your dashboard
• Post your availability
• Start accepting work opportunities

Login here:
https://necto.in/login.php

– Team Necto
";

    $headers = "From: Necto <no-reply@necto.in>";
    @mail($to, $subject, $message, $headers);

    /* ================= WEB PUSH NOTIFICATION ================= */
    $auth = [
        'VAPID' => [
            'subject' => 'mailto:admin@necto.in',
            'publicKey' => VAPID_PUBLIC,
            'privateKey' => VAPID_PRIVATE,
        ],
    ];

    $webPush = new WebPush($auth);

    $subStmt = $conn->prepare("
        SELECT endpoint, p256dh, auth
        FROM web_push_subscriptions
        WHERE user_id = ?
    ");
    $subStmt->bind_param("i", $sp['user_id']);
    $subStmt->execute();
    $subs = $subStmt->get_result();

    while ($row = $subs->fetch_assoc()) {

        $subscription = Subscription::create([
            'endpoint' => $row['endpoint'],
            'keys' => [
                'p256dh' => $row['p256dh'],
                'auth' => $row['auth'],
            ],
        ]);

        $payload = json_encode([
            'title' => 'Profile Verified 🎉',
            'body'  => 'Your profile has been verified. You can now post availability.'
        ]);

        $webPush->sendOneNotification($subscription, $payload);
    }

    $webPush->flush();

    header("Location: admin_staff_verification.php?approved=1");
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Verify Staff | Admin</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="/assets/css/dashboard.css">
</head>

<body>

<!-- NAVBAR -->
<div class="navbar">
    <div class="brand">Necto Admin</div>
    <div class="menu">
        <a href="admin_staff_verification.php">← Back</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<!-- CONTENT -->
<div class="dashboard-wrapper">
<div class="card" style="max-width:900px;">

<h2>Staff Profile Review</h2>

<?php if ($sp['profile_photo']): ?>
<img src="/<?= e($sp['profile_photo']) ?>"
     style="max-width:180px;border-radius:12px;margin-bottom:20px;">
<?php endif; ?>

<p><b>Name:</b> <?= e($sp['full_name']) ?></p>
<p><b>Email:</b> <?= e($sp['email']) ?></p>
<p><b>Age:</b> <?= (int)$sp['age'] ?></p>
<p><b>DOB:</b> <?= e($sp['dob']) ?></p>
<p><b>Gender:</b> <?= e($sp['gender']) ?></p>
<p><b>Address:</b><br><?= nl2br(e($sp['address'])) ?></p>

<hr>

<p><b>Qualification:</b> <?= e($sp['qualification']) ?></p>
<p><b>College:</b> <?= e($sp['college']) ?></p>
<p><b>Experience:</b> <?= (int)$sp['experience_years'] ?> years</p>
<p><b>Current Institution:</b> <?= e($sp['current_institution']) ?></p>
<p><b>Working Role:</b> <?= e($sp['working_role']) ?></p>
<p><b>Willing Roles:</b> <?= e($sp['willing_roles']) ?></p>
<p><b>Preferred Location:</b> <?= e($sp['preferred_location']) ?></p>

<hr>

<!-- VERIFY -->
<form method="post">
    <button style="
        padding:14px 24px;
        background:#16a34a;
        color:#fff;
        border:none;
        border-radius:10px;
        font-size:16px;
        cursor:pointer;
    ">
        ✅ Verify & Notify Staff
    </button>
</form>

<!-- REJECT -->
<hr>

<form method="post" style="margin-top:20px;">
    <textarea
        name="rejection_reason"
        placeholder="Reason for rejection (required)"
        required
        style="width:100%;padding:12px;border-radius:8px;border:1px solid #ccc;margin-bottom:12px;"
    ></textarea>

    <button
        type="submit"
        name="reject"
        style="
            padding:14px 24px;
            background:#dc2626;
            color:#fff;
            border:none;
            border-radius:10px;
            font-size:16px;
            cursor:pointer;
        ">
        ❌ Reject Profile
    </button>
</form>

</div>
</div>

</body>
</html>


