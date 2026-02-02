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
$error = "";

/* ================= FETCH HOSPITAL ================= */
$stmt = $conn->prepare("
    SELECT hospital_name, verified 
    FROM hospital_profiles 
    WHERE user_id = ?
");
$stmt->bind_param("i", $hospital_id);
$stmt->execute();
$hospital = $stmt->get_result()->fetch_assoc();

if (!$hospital) die("Complete hospital profile first.");
if ($hospital['verified'] !== 'yes') die("Hospital verification pending.");

/* ================= HANDLE POST ================= */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $shift_date = $_POST['shift_date'] ?? '';
    $start_time = $_POST['start_time'] ?? '';
    $end_time   = $_POST['end_time'] ?? '';

    $degree_required = $_POST['degree_required'] ?? '';
    $stream_required = $_POST['stream_required'] ?? '';
    $role_required   = trim($_POST['role_required'] ?? '');

    $latitude  = $_POST['latitude'] ?? '';
    $longitude = $_POST['longitude'] ?? '';

    $payment_amount = floatval($_POST['payment_amount'] ?? 0);
    $payment_type   = $_POST['payment_type'] ?? '';

    $notes = $_POST['notes'] ?? '';

    if (
        !$shift_date || !$start_time || !$end_time ||
        !$degree_required || !$stream_required || !$role_required ||
        !$latitude || !$longitude || $payment_amount <= 0
    ) {
        $error = "All mandatory fields are required.";
    } elseif ($end_time <= $start_time) {
        $error = "End time must be after start time.";
    } else {

        $stmt = $conn->prepare("
            INSERT INTO hospital_shifts (
                hospital_id,
                hospital_name,
                required_degree,
                required_stream,
                role_required,
                shift_date,
                start_time,
                end_time,
                latitude,
                longitude,
                payment_amount,
                payment_type,
                notes,
                status
            ) VALUES (
                ?,?,?,?,?,?,?,?,?,?,?,?,?,'open'
            )
        ");

        $stmt->bind_param(
            "isssssssssdss",
            $hospital_id,
            $hospital['hospital_name'],
            $degree_required,
            $stream_required,
            $role_required,
            $shift_date,
            $start_time,
            $end_time,
            $latitude,
            $longitude,
            $payment_amount,
            $payment_type,
            $notes
        );

        $stmt->execute();
        header("Location: post_shift.php?success=1");
        exit;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Post Shift</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="stylesheet" href="/assets/css/dashboard.css">

<style>
body{
    margin:0;
    background:linear-gradient(135deg,#0f766e,#0d9488);
    font-family:Segoe UI,Arial;
}

.dashboard-wrapper{
    display:flex;
    justify-content:center;
    padding:20px 12px;
}

.card{
    width:100%;
    max-width:720px;
    background:#fff;
    border-radius:16px;
    padding:22px;
    box-shadow:0 10px 25px rgba(0,0,0,.12);
}

h2{margin-top:0}

label{
    font-weight:600;
    margin-bottom:6px;
    display:block;
}

input, select, textarea{
    width:100%;
    padding:12px;
    border-radius:10px;
    border:1px solid #ccc;
    margin-bottom:14px;
}

.form-row{
    display:grid;
    grid-template-columns:1fr 1fr;
    gap:12px;
}

@media(max-width:600px){
    .form-row{grid-template-columns:1fr;}
}

#map{
    height:240px;
    border-radius:12px;
    border:1px solid #ddd;
    margin-bottom:14px;
}

button{
    width:100%;
    padding:14px;
    background:#0f766e;
    color:#fff;
    border:none;
    border-radius:12px;
    font-size:16px;
}

.instructions{
    margin-top:20px;
    background:#f8fafc;
    padding:14px;
    border-left:4px solid #0f766e;
    border-radius:10px;
    font-size:14px;
}
</style>
</head>

<body>

<div class="navbar">
    <div class="brand">Necto</div>
    <div class="menu">
        <a href="/hospital/dashboard_hospital.php">Home</a>
        <a class="active">Post Shift</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<div class="dashboard-wrapper">
<div class="card">

<h2>Post Hospital Shift</h2>

<?php if (isset($_GET['success'])): ?>
<p style="color:green">✅ Shift posted successfully</p>
<?php endif; ?>

<?php if ($error): ?>
<p style="color:red"><?= htmlspecialchars($error) ?></p>
<?php endif; ?>

<form method="POST">

<label>Hospital</label>
<input value="<?= htmlspecialchars($hospital['hospital_name']) ?>" disabled>

<label>Date</label>
<input type="date" name="shift_date" required>

<div class="form-row">
<input type="time" name="start_time" required>
<input type="time" name="end_time" required>
</div>

<label>Required Degree</label>
<select name="degree_required" required>
<option value="">Select</option>
<option>Diploma</option>
<option>BSc</option>
<option>MSc</option>
<option>BPT</option>
</select>

<label>Required Stream</label>
<select name="stream_required" required>
<option value="">Select</option>
<option>Cardiac Care Technology</option>
<option>Nursing</option>
<option>Medical Lab Technology</option>
<option>Imaging Technology</option>
<option>Physiotherapy</option>
</select>

<label>Required Role</label>
<input name="role_required" required>

<label>Location</label>
<div id="map"></div>
<input type="hidden" name="latitude" id="latitude">
<input type="hidden" name="longitude" id="longitude">

<label>Payment Amount (₹)</label>
<input type="number" name="payment_amount" required>

<label>Payment Type</label>
<select name="payment_type" required>
<option value="per_shift">Per Shift</option>
<option value="per_hour">Per Hour</option>
</select>

<label>Notes (optional)</label>
<textarea name="notes"></textarea>

<button type="submit">Post Shift</button>

</form>

<div class="instructions">
<strong>Instructions</strong>
<ul>
<li>Only staff matching degree & stream will be shown</li>
<li>Distance is calculated using map location</li>
<li>Contact details shown only after staff accepts</li>
<li>If staff rejects, profile remains available</li>
</ul>
</div>

</div>
</div>

<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCy0UN1VaNgDAMjR0oPnaleC2aidKvzd60&callback=initMap" async defer></script>
<script>
let map, marker;
function initMap(){
  const center={lat:12.9716,lng:77.5946};
  map=new google.maps.Map(document.getElementById("map"),{zoom:13,center});
  marker=new google.maps.Marker({map,position:center,draggable:true});
  set(center.lat,center.lng);
  marker.addListener("dragend",e=>set(e.latLng.lat(),e.latLng.lng()));
  map.addListener("click",e=>{marker.setPosition(e.latLng);set(e.latLng.lat(),e.latLng.lng());});
}
function set(lat,lng){
  latitude.value=lat;
  longitude.value=lng;
}
</script>

</body>
</html>

