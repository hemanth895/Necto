 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

session_start();
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= AUTH ================= */
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'hospital') {
    header("Location: /login.php");
    exit;
}

$user_id = $_SESSION['user_id'];
$error = "";

/* ================= FETCH PROFILE ================= */
$stmt = $conn->prepare("
    SELECT hospital_name, verified 
    FROM hospital_profiles 
    WHERE user_id = ?
");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$hasProfile = false;
$verifiedStatus = "no";
$hospitalName = "";

if ($result->num_rows === 1) {
    $hasProfile = true;
    $row = $result->fetch_assoc();
    $verifiedStatus = $row['verified'];
    $hospitalName = $row['hospital_name'];
}

/* ================= HANDLE SUBMIT ================= */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !$hasProfile) {

    $required = [
        'hospital_name',
        'address',
        'telephone',
        'contact_number',
        'pincode'
    ];

    foreach ($required as $field) {
        if (empty($_POST[$field])) {
            $error = "All fields are mandatory.";
        }
    }

    if (empty($_POST['consent'])) {
        $error = "You must agree to the Terms & Conditions and Privacy Policy.";
    }

    if (empty($_FILES['hospital_image']['name'])) {
        $error = "Hospital / Clinic image is required.";
    }

    if (!$error) {

        $hospital_name  = trim($_POST['hospital_name']);
        $address        = trim($_POST['address']);
        $telephone      = trim($_POST['telephone']);
        $contact_number = trim($_POST['contact_number']);
        $pincode        = trim($_POST['pincode']);

        /* ===== IMAGE UPLOAD ===== */
        $uploadDir = $_SERVER['DOCUMENT_ROOT'] . "/uploads/hospitals/";
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $fileName = time() . "_" . basename($_FILES["hospital_image"]["name"]);
        $targetFile = $uploadDir . $fileName;

        $allowed = ['jpg','jpeg','png'];
        $ext = strtolower(pathinfo($targetFile, PATHINFO_EXTENSION));

        if (!in_array($ext, $allowed)) {
            $error = "Only JPG, JPEG or PNG images are allowed.";
        } elseif (!move_uploaded_file($_FILES["hospital_image"]["tmp_name"], $targetFile)) {
            $error = "Image upload failed.";
        } else {

            $imagePath = "/uploads/hospitals/" . $fileName;

            $stmt = $conn->prepare("
                INSERT INTO hospital_profiles
                (user_id, hospital_name, address, telephone, contact_number, pincode, hospital_image, consent, verified)
                VALUES (?,?,?,?,?,?,?, 'yes', 'pending')
            ");
            $stmt->bind_param(
                "issssss",
                $user_id,
                $hospital_name,
                $address,
                $telephone,
                $contact_number,
                $pincode,
                $imagePath
            );

            if ($stmt->execute()) {
                header("Location: hospital_profile.php");
                exit;
            } else {
                $error = "Database error. Please try again.";
            }
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Hospital Profile | Necto</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="/assets/css/dashboard.css">

    <!-- ✅ ADDED: spinner CSS (does NOT touch dashboard.css) -->
    <style>
        body.waiting { cursor: wait; }
        #loadingOverlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(255,255,255,0.7);
            z-index: 9999;
        }
        #loadingOverlay::after {
            content: "";
            width: 40px;
            height: 40px;
            border: 4px solid #ccc;
            border-top-color: #0f766e;
            border-radius: 50%;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            to { transform: rotate(360deg) translate(-50%, -50%); }
        }
    </style>
</head>

<body>
<div id="loadingOverlay"></div>

<div class="navbar">
    <div class="brand">Necto</div>
    <div class="menu">
        <a href="dashboard_hospital.php">Home</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<div class="dashboard-wrapper">
    <div class="card hospital-card">

        <?php if ($hasProfile): ?>

            <h2><?= htmlspecialchars($hospitalName) ?></h2>

            <?php if ($verifiedStatus === 'pending'): ?>
                <div class="warning-box">
                    <strong>Verification Pending</strong><br><br>
                    Your hospital profile has been submitted and is under admin review.
                </div>

            <?php elseif ($verifiedStatus === 'yes'): ?>
                <div class="success-box">
                    <strong>Verified</strong><br><br>
                    Your hospital profile is verified.
                </div>
            <?php endif; ?>

        <?php else: ?>

            <h2>Create Hospital Profile</h2>
            <p style="margin-bottom:20px;">
                All fields are mandatory. Profile can be created only once.
            </p>

            <?php if ($error): ?>
                <div class="warning-box"><?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <form method="POST" enctype="multipart/form-data" class="form-grid">

                <div class="form-group">
                    <input type="text" name="hospital_name" placeholder="Hospital / Clinic Name" required>
                </div>

                <div class="form-group full">
                    <textarea name="address" placeholder="Full Address" required></textarea>
                </div>

                <div class="form-group">
                    <input type="text" name="telephone" placeholder="Telephone Number" required>
                </div>

                <div class="form-group">
                    <input type="text" name="contact_number" placeholder="Contact Mobile Number" required>
                </div>

                <div class="form-group">
                    <input type="text" name="pincode" placeholder="Pincode" required>
                </div>

                <div class="form-group full">
                    <label>Hospital / Clinic Image</label>
                    <input type="file" name="hospital_image" accept="image/*" required class="file-input">
                </div>

                <div class="form-group full consent-box">
                    <label>
                        <input type="checkbox" name="consent" value="yes" required>
                        I agree to the
                        <a href="/terms.php" target="_blank">Terms & Conditions</a>
                        and
                        <a href="/privacy.php" target="_blank">Privacy Policy</a>
                        of Necto.
                    </label>
                </div>

                <div class="form-group full">
                    <!-- ✅ ONLY CHANGE: added id -->
                    <button type="submit" id="saveBtn" class="primary-btn full-btn">
                        Save Hospital Profile
                    </button>
                </div>

            </form>

        <?php endif; ?>

    </div>
</div>

<!-- ✅ ADDED: JS (no logic touched) -->
<script>
document.querySelector("form")?.addEventListener("submit", function () {
    document.body.classList.add("waiting");
    document.getElementById("loadingOverlay").style.display = "block";
    const btn = document.getElementById("saveBtn");
    if (btn) {
        btn.disabled = true;
        btn.innerText = "Saving...";
    }
});
</script>

</body>
</html>

