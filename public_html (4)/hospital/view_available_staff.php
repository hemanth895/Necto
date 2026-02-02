 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= AUTH ================= */
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'hospital') {
    header("Location: /login.php");
    exit;
}

$hospital_id = $_SESSION['user_id'];

/* ================= SHIFT ID RESOLUTION ================= */
$shift_id = 0;

if (isset($_GET['shift_id'])) {
    $shift_id = (int)$_GET['shift_id'];
} elseif (isset($_POST['shift_id'])) {
    $shift_id = (int)$_POST['shift_id'];
} elseif (isset($_GET['id'])) {
    $shift_id = (int)$_GET['id'];
}

/* ================= FALLBACK: LATEST OPEN SHIFT ================= */
if ($shift_id <= 0) {
    $fallback = $conn->prepare("
        SELECT id 
        FROM hospital_shifts
        WHERE hospital_id = ?
          AND status = 'open'
        ORDER BY id DESC
        LIMIT 1
    ");
    $fallback->bind_param("i", $hospital_id);
    $fallback->execute();
    $row = $fallback->get_result()->fetch_assoc();
    if ($row) {
        $shift_id = (int)$row['id'];
    }
}

/* ================= FINAL GUARD ================= */
if ($shift_id <= 0) {
    die("No open shifts found.");
}

/* ================= FETCH SHIFT ================= */
$stmt = $conn->prepare("
    SELECT 
        degree_required,
        required_stream,
        shift_date,
        start_time,
        end_time,
        latitude,
        longitude,
        status
    FROM hospital_shifts
    WHERE id = ? AND hospital_id = ?
");
$stmt->bind_param("ii", $shift_id, $hospital_id);
$stmt->execute();
$shift = $stmt->get_result()->fetch_assoc();

if (!$shift || $shift['status'] !== 'open') {
    die("Shift not available.");
}

/* ================= LOCATION RADIUS ================= */
$radius_km = 20;

/* ================= MATCH STAFF ================= */
$stmt = $conn->prepare("
    SELECT
        sa.id AS availability_id,
        sa.staff_id,
        sa.full_name,
        sa.degree,
        sa.specialization,
        sa.experience_years,
        sa.current_institution,
        sa.working_role,
        sa.latitude,
        sa.longitude,

        (
            6371 * ACOS(
                COS(RADIANS(?))
                * COS(RADIANS(sa.latitude))
                * COS(RADIANS(sa.longitude) - RADIANS(?))
                + SIN(RADIANS(?))
                * SIN(RADIANS(sa.latitude))
            )
        ) AS distance

    FROM staff_availability sa
    WHERE
        sa.status = 'available'
        AND sa.degree = ?
        AND sa.specialization = ?
        AND sa.work_date = ?
        AND sa.start_time <= ?
        AND sa.end_time >= ?

    HAVING distance <= ?
    ORDER BY distance ASC
");

$stmt->bind_param(
    "dddssssdi",
    $shift['latitude'],
    $shift['longitude'],
    $shift['latitude'],
    $shift['degree_required'],
    $shift['required_stream'],
    $shift['shift_date'],
    $shift['start_time'],
    $shift['end_time'],
    $radius_km
);

$stmt->execute();
$staffResult = $stmt->get_result();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Available Staff | Necto</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="/assets/css/dashboard.css">
</head>

<body>

<div class="navbar">
    <div class="brand">Necto</div>
    <div class="menu">
        <a href="dashboard_hospital.php">Home</a>
        <a href="post_shift.php">Post Shift</a>
        <a href="logout.php">Logout</a>
    </div>
</div>

<div class="dashboard-wrapper">
    <div class="card">

        <h2>Available Staff</h2>

        <p style="color:#555;margin-bottom:20px;">
            Degree: <strong><?= htmlspecialchars($shift['degree_required']??'') ?></strong> |
            Stream: <strong><?= htmlspecialchars($shift['required_stream']) ?></strong> |
            Date: <strong><?= htmlspecialchars($shift['shift_date']) ?></strong>
        </p>

        <?php if ($staffResult->num_rows === 0): ?>
            <div style="background:#fff3cd;border:1px solid #ffeeba;padding:18px;border-radius:8px;text-align:center;">
                <strong>No staff available</strong>
                <p>No matching staff found within <?= $radius_km ?> km.</p>
            </div>
        <?php else: ?>

        <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px;">
        <?php while ($s = $staffResult->fetch_assoc()): ?>
             <div style="border:1px solid #e5e7eb;padding:16px;border-radius:12px;background:#fff;">
    
    <div style="display:flex;gap:12px;align-items:center;">
        <img 
            src="/uploads/staff/<?= htmlspecialchars($s['profile_photo'] ?? 'default.png') ?>"
            alt="Profile"
            style="width:64px;height:64px;border-radius:50%;object-fit:cover;border:1px solid #ddd;"
        >
        <div>
            <strong><?= htmlspecialchars($s['full_name'] ?? '') ?></strong><br>
            <span style="color:#555;">
                <?= htmlspecialchars($s['degree'] ?? '') ?> – <?= htmlspecialchars($s['specialization'] ?? '') ?>
            </span>
        </div>
    </div>

    <div style="margin-top:10px;font-size:14px;color:#444;">
        <div>Experience: <strong><?= (int)($s['experience_years'] ?? 0) ?> years</strong></div>
        <div>Institution: <?= htmlspecialchars($s['current_institution'] ?? '') ?></div>
        <div>Role: <?= htmlspecialchars($s['working_role'] ?? '') ?></div>
        <div>📍 <?= round($s['distance'], 1) ?> km away</div>
    </div>

    <form method="post" action="send_request.php" style="margin-top:12px;">
        <input type="hidden" name="shift_id" value="<?= $shift_id ?>">
        <input type="hidden" name="availability_id" value="<?= $s['availability_id'] ?>">
        <button class="primary-btn" style="width:100%;">Send Request</button>
    </form>

</div>

        <?php endwhile; ?>
        </div>

        <?php endif; ?>

    </div>
</div>

</body>
</html>
