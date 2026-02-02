 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

session_start();
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";

/* ================= AUTH ================= */
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'staff') {
    header("Location: /login.php");
    exit;
}

$user_id = $_SESSION['user_id'];
$error = "";

/* ================= FETCH PROFILE ================= */
$stmt = $conn->prepare("
    SELECT 
        id,
        college,
        current_institution
    FROM staff_profiles 
    WHERE user_id=?
");

$stmt->bind_param("i", $user_id);
$stmt->execute();
$profile = $stmt->get_result()->fetch_assoc();

/* ================= BLOCK RESUBMISSION ================= */
if ($profile && $_SERVER['REQUEST_METHOD'] === 'POST') {
    header("Location: /staff/staff_profile.php?success=1");
    exit;
}

/* ================= HANDLE POST ================= */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !$profile) {

    $required = [
        'full_name','age','dob','gender','address',
        'email','mobile','emergency_mobile',
        'degree','stream','college','experience_years',
        'current_institution',
        'working_role','willing_roles','preferred_location','consent'
    ];

    foreach ($required as $field) {
        if (empty($_POST[$field])) {
            $error = "All fields are mandatory.";
            break;
        }
    }

    if ($_POST['mobile'] === $_POST['emergency_mobile']) {
        $error = "Emergency contact must be different from mobile number.";
    }

    if ($_POST['stream'] === 'Other' && empty($_POST['other_stream'])) {
        $error = "Please mention your specialization.";
    }

    /* ================= PHOTO UPLOAD ================= */
    $photoPath = null;

    if (!empty($_FILES['profile_photo']['name'])) {
        $dir = $_SERVER['DOCUMENT_ROOT'] . "/uploads/staff/";
        if (!is_dir($dir)) mkdir($dir, 0755, true);

        $ext = pathinfo($_FILES['profile_photo']['name'], PATHINFO_EXTENSION);
        $file = "staff_" . $user_id . "_" . time() . "." . $ext;

        if (!move_uploaded_file($_FILES['profile_photo']['tmp_name'], $dir . $file)) {
            $error = "Profile photo upload failed.";
        }

        $photoPath = "uploads/staff/" . $file;
    }

    /* ================= SAVE ================= */
    if (!$error) {

        $verified = 'no';
        $other_stream = ($_POST['stream'] === 'Other') ? $_POST['other_stream'] : null;

        $sql = "INSERT INTO staff_profiles (
            user_id, full_name, age, dob, gender, address,
            email, mobile, emergency_mobile,
            degree, stream, other_stream,
            college, experience_years, current_institution,
            working_role, willing_roles, preferred_location,
            profile_photo, consent, verified
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param(
            "isisssssssssssssssssi",
            $user_id,
            $_POST['full_name'],
            $_POST['age'],
            $_POST['dob'],
            $_POST['gender'],
            $_POST['address'],
            $_POST['email'],
            $_POST['mobile'],
            $_POST['emergency_mobile'],
            $_POST['degree'],
            $_POST['stream'],
            $other_stream,
            $_POST['college'],
            $_POST['experience_years'],
            $_POST['current_institution'],
            $_POST['working_role'],
            $_POST['willing_roles'],
            $_POST['preferred_location'],
            $photoPath,
            $_POST['consent'],
            $verified
        );

        $stmt->execute();
        header("Location: /staff/staff_profile.php?success=1");
        exit;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Staff Profile | Necto</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
body{
    margin:0;
    background:linear-gradient(135deg,#0f766e,#0d9488);
    font-family:Segoe UI,Arial;
    display:flex;
    justify-content:center;
    padding:30px;
}
.card{
    background:#fff;
    max-width:900px;
    width:100%;
    border-radius:18px;
    padding:30px;
}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
@media(max-width:768px){.grid{grid-template-columns:1fr}}
input,select,textarea{
    padding:12px;border-radius:8px;border:1px solid #ccc;width:100%
}
button{
    width:100%;margin-top:25px;padding:14px;
    background:#0f766e;color:#fff;border:none;border-radius:10px
}
.error{background:#fee2e2;color:#991b1b;padding:12px;border-radius:8px;margin-bottom:15px}
.success{background:#dcfce7;color:#166534;padding:14px;border-radius:10px;margin-bottom:15px}
.locked{background:#ecfeff;color:#065f46;padding:18px;border-radius:12px}

/* LOADER */
#loadingOverlay{
    position:fixed;
    inset:0;
    background:rgba(255,255,255,0.85);
    display:none;
    align-items:center;
    justify-content:center;
    z-index:9999;
}
.loader-box{text-align:center;color:#0f766e}
.spinner{
    width:40px;height:40px;
    border:4px solid #d1fae5;
    border-top:4px solid #0f766e;
    border-radius:50%;
    animation:spin 1s linear infinite;
    margin:0 auto 10px
}
@keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>

<body>

<div class="card">

<h2>Staff Profile</h2>
<p>Create profile → Verification → Start working</p>
   <p>note " Once Profile created later cannot be altered" </p>

<?php if (isset($_GET['success'])): ?>
<div class="success">
    ✅ Profile created successfully.<br>
    🔒 Profile sent for verification.<br><br>
    <a href="/staff/dashboard_staff.php"
       style="display:inline-block;padding:12px 20px;background:#0f766e;color:#fff;text-decoration:none;border-radius:8px">
       ← Go to Dashboard
    </a>
</div>
<?php endif; ?>

<?php if ($error): ?>
<div class="error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<?php if ($profile): ?>
<div class="locked">
    🕒 Your profile is under verification.<br><br>
    You will be notified once approved.
</div>
<?php else: ?>

<form method="POST" enctype="multipart/form-data" id="profileForm">

<h4>Basic Details</h4>
<div class="grid">
<input name="full_name" placeholder="Full Name" required>
<input name="age" type="number" placeholder="Age" required>
<input name="dob" type="date" required>
</div>

<div class="grid">
<select name="gender" required>
<option value="">Gender</option>
<option>Male</option>
<option>Female</option>
<option>Other</option>
</select>
<textarea name="address" placeholder="Address" required></textarea>
</div>

<h4>Contact</h4>
<div class="grid">
<input name="email" type="email" placeholder="Email" required>
<input name="mobile" placeholder="Mobile" required>
<input name="emergency_mobile" placeholder="Emergency Contact" required>
</div>

<h4>Professional</h4>
<div class="grid">
<select name="degree" required>
<option value="">Degree</option>
<option>Diploma</option>
<option>BSc</option>
<option>MSc</option>
<option>BPT</option>
<option>Other</option>
</select>

<select name="stream" id="stream" required>
<option value="">Specialization</option>
<option>Cardiac Care Technology</option>
<option>Nursing</option>
<option>Medical Lab Technology</option>
<option>Imaging Technology</option>
<option>Operation Theatre</option>
<option>Optometry</option>
<option>Physiotherapy</option>
<option>Dialysis Technology</option>
<option>Emergency Medical Technology</option>
<option>Respiratory Technology</option>
<option>Perfusion Technology</option>
<option>Anaesthesia Technology</option>
<option>Other</option>
</select>

<input name="other_stream" id="other_stream"
       placeholder="Other Specialization"
       style="display:none;">

<input name="college" placeholder="College" required>
<input name="experience_years" type="number" placeholder="Experience (years)" required>
<input name="current_institution" placeholder="Current Institution" required>
</div>

<div class="grid">
<input name="working_role" placeholder="Current Role" required>
<input name="willing_roles" placeholder="Willing Roles" required>
<input name="preferred_location" placeholder="Preferred Location" required>
</div>

<h4>Profile Photo</h4>
<input type="file" name="profile_photo" accept="image/*" required>

<br><br>
<label>
<input type="checkbox" name="consent" value="1" required>
 I agree to the
 <a href="/staff/staff_consent.php" target="_blank">Consent Form & Privacy Policy</a>
</label>

<button type="submit">Save Profile</button>

</form>

<script>
const stream=document.getElementById('stream');
const other=document.getElementById('other_stream');
stream.addEventListener('change',()=>{other.style.display=stream.value==='Other'?'block':'none'});
</script>

<?php endif; ?>

</div>

<!-- LOADER -->
<div id="loadingOverlay">
    <div class="loader-box">
        <div class="spinner"></div>
        Saving profile…<br>
        <small>Time elapsed: <span id="timer">0</span>s</small>
    </div>
</div>

<script>
const form=document.getElementById('profileForm');
const overlay=document.getElementById('loadingOverlay');
const timerEl=document.getElementById('timer');
let s=0;
if(form){
 form.addEventListener('submit',()=>{
  overlay.style.display='flex';
  setInterval(()=>{timerEl.textContent=++s},1000);
 });
}
</script>

</body>
</html>
