 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

requireLogin();
requireRole("hospital");

$user_id = $_SESSION['user_id'];

/* ================= FETCH HOSPITAL PROFILE ================= */
$stmt = $conn->prepare("
    SELECT hospital_name, verified 
    FROM hospital_profiles 
    WHERE user_id = ?
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$hasProfile = false;
$isVerified = false;
$hospitalName = "Hospital";

if ($result->num_rows === 1) {
    $hasProfile = true;
    $row = $result->fetch_assoc();
    $hospitalName = $row['hospital_name'];
    $isVerified = ($row['verified'] === 'yes');
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hospital Dashboard | Necto</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="/assets/css/dashboard.css">
</head>

<body>

<!-- ================= NAVBAR ================= -->
<div class="navbar">
    <div class="brand">Necto</div>

    <div class="menu">
        <a href="dashboard_hospital.php">Home</a>

        <?php if (!$hasProfile): ?>
            <a href="hospital_profile.php">Create Profile</a>

        <?php elseif (!$isVerified): ?>
            <a href="hospital_profile.php">Profile</a>
            <a href="hospital_verification_status.php">Verification Status</a>

        <?php else: ?>
            <a href="post_shift.php">Post Shift</a>
            <a href="view_available_staff.php">View Available Staff</a>
   
   
</a>

        <?php endif; ?>

        <a href="about_necto.php">About Necto</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<!-- ================= CONTENT ================= -->
<div class="dashboard-wrapper">
    <div class="card" style="max-width:1000px;">

        <!-- NO PROFILE -->
        <?php if (!$hasProfile): ?>

            <h2>Welcome to Necto</h2>
            <p>
                To start posting shifts and accessing verified paramedical staff,
                please create your hospital or clinic profile.
            </p>

            <a href="hospital_profile.php" class="primary-btn">
                ➕ Create Hospital Profile
            </a>

        <!-- PROFILE CREATED BUT NOT VERIFIED -->
        <?php elseif (!$isVerified): ?>

            <h2>Hello, <?= htmlspecialchars($hospitalName) ?></h2>

            <div class="warning-box">
                <strong>Verification Pending</strong><br><br>
                Your hospital profile has been submitted but is not yet verified.
                Once verified by admin, you can start posting shifts.
            </div>

            <div style="margin-top:20px;">
                <a href="hospital_verification_status.php" class="secondary-btn">
                    View Verification Status
                </a>
            </div>

        <!-- VERIFIED -->
        <?php else: ?>

            <h2><?= htmlspecialchars($hospitalName) ?> Dashboard</h2>

            <p>
                Your hospital is verified. You can now post shifts and
                view available paramedical staff.
            </p>

            <div class="action-grid">

                <a href="post_shift.php" class="action-card">
                    ➕ Post a Shift
                </a>

                <a href="view_available_staff.php" class="action-card">
                    👥 View Available Staff
                </a>

            </div>

        <?php endif; ?>

    </div>
</div>

</body>
</html>

