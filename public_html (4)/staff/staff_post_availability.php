 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
session_start();

require_once $_SERVER['DOCUMENT_ROOT']."/config/db.php";
require_once $_SERVER['DOCUMENT_ROOT']."/includes/karnataka_districts.php";
require_once $_SERVER['DOCUMENT_ROOT']."/includes/karnataka_talukas.php";

/* ========= AUTH ========= */
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'staff') {
    header("Location: /login.php");
    $stmt->execute();


header("Location: $redirect");
exit;

    exit;
}

$staff_id = $_SESSION['user_id'];
$message = "";

/* ========= FETCH STAFF PROFILE ========= */
$stmt = $conn->prepare("
    SELECT 
        full_name,
        degree,
        stream,
        experience_years,
        current_institution,
        working_role,
        age,
        gender,
        profile_photo,
        verified
    FROM staff_profiles
    WHERE user_id = ?
");
$stmt->bind_param("i", $staff_id);
$stmt->execute();
$profile = $stmt->get_result()->fetch_assoc();

if (!$profile) die("Complete staff profile first.");
if ($profile['verified'] !== 'yes') die("Profile not verified.");

/* ========= CHECK LAST AVAILABILITY ========= */
$canPost = true;
$nextAllowedAt = null;

$last = $conn->prepare("
    SELECT work_date, end_time, status
    FROM staff_availability
    WHERE staff_id = ?
    ORDER BY work_date DESC, end_time DESC
    LIMIT 1
");
$last->bind_param("i", $staff_id);
$last->execute();
$lastRow = $last->get_result()->fetch_assoc();

if ($lastRow) {
    $endDateTime = strtotime($lastRow['work_date'].' '.$lastRow['end_time']);
    if ($lastRow['status'] !== 'closed' && time() < $endDateTime) {
        $canPost = false;
        $nextAllowedAt = date('d M Y, h:i A', $endDateTime);
    }
}

/* ========= HANDLE POST ========= */
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $canPost) {

    $district   = $_POST['district'] ?? '';
    $taluka     = $_POST['taluka'] ?? '';
    $work_date  = $_POST['work_date'] ?? '';
    $start_time = $_POST['start_time'] ?? '';
    $end_time   = $_POST['end_time'] ?? '';
    $latitude   = $_POST['latitude'] ?? '';
    $longitude  = $_POST['longitude'] ?? '';

    if (!$district || !$taluka || !$work_date || !$start_time || !$end_time || !$latitude || !$longitude) {
        $message = "All fields including map location are required.";
    } elseif ($end_time <= $start_time) {
        $message = "End time must be after start time.";
    } else {

        $stmt = $conn->prepare("
            INSERT INTO staff_availability (
                staff_id,
                state,
                district,
                taluka,
                work_date,
                start_time,
                end_time,
                latitude,
                longitude,
                status
            ) VALUES (?,?,?,?,?,?,?,?,?, 'available')
        ");
        $state = 'Karnataka';

        $stmt->bind_param(
            "issssssdd",
            $staff_id,
            $state,
            $district,
            $taluka,
            $work_date,
            $start_time,
            $end_time,
            $latitude,
            $longitude
        );
        $stmt->execute();

        header("Location: /staff/staff_post_availability.php?success=1");
        exit;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Create Availability | Necto</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link rel="stylesheet" href="/assets/css/dashboard.css">
<link rel="stylesheet" href="/assets/css/staff.css">

<style>
.profile-photo{width:80px;height:80px;border-radius:50%;object-fit:cover}
.instruction-box{
    margin-top:20px;padding:14px;background:#f8fafc;
    border-left:4px solid #0f766e;border-radius:8px;font-size:14px
}
#map{width:100%;height:280px;border-radius:12px;margin-top:10px}
</style>
</head>

<body>

<div class="navbar">
    <div class="brand">Necto</div>
    <div class="menu">
        <a href="/staff/dashboard_staff.php">Home</a>
        <a class="active">Post Availability</a>
        <a href="/logout.php">Logout</a>
    </div>
</div>

<div class="dashboard-wrapper">
<div class="card">

<h2>Create Availability</h2>

<?php if (isset($_GET['success'])): ?>
<div style="background:#dcfce7;padding:16px;border-radius:10px;margin-bottom:15px;">
    ✅ Availability posted successfully.<br><br>
    <a href="/staff/dashboard_staff.php"
       style="background:#0f766e;color:#fff;padding:10px 18px;border-radius:8px;text-decoration:none;">
       ← Back to Dashboard
    </a>
</div>
<?php endif; ?>

<?php if (!$canPost): ?>
<div style="background:#ecfeff;padding:16px;border-radius:10px;">
    ⏳ You can post next availability after <b><?= $nextAllowedAt ?></b>
</div>
<?php else: ?>

<?php if ($message): ?>
<p style="color:red"><?= htmlspecialchars($message) ?></p>
<?php endif; ?>

<div class="profile-summary">
<?php if ($profile['profile_photo']): ?>
<img src="/<?= htmlspecialchars($profile['profile_photo']) ?>" class="profile-photo">
<?php endif; ?>
<div>
<b><?= htmlspecialchars($profile['full_name']) ?></b><br>
<?= htmlspecialchars($profile['degree']) ?> – <?= htmlspecialchars($profile['stream']) ?><br>
<?= htmlspecialchars($profile['experience_years']) ?> years experience<br>
<?= htmlspecialchars($profile['current_institution']) ?><br>
<?= htmlspecialchars($profile['working_role']) ?>
</div>
</div>

<form method="post">
<input type="hidden" name="latitude" id="latitude">
<input type="hidden" name="longitude" id="longitude">

<p><strong>State:</strong> Karnataka</p>

<div class="form-row">
<select name="district" id="district" required>
<option value="">Select District</option>
<?php foreach ($karnataka_districts as $d): ?>
<option value="<?= htmlspecialchars($d) ?>"><?= htmlspecialchars($d) ?></option>
<?php endforeach; ?>
</select>

<select name="taluka" id="taluka" required>
<option value="">Select Taluka</option>
</select>
</div>

<h4>Select Exact Location</h4>
<div id="map"></div>

<div class="form-row">
<input type="date" name="work_date" required>
<input type="time" name="start_time" required>
<input type="time" name="end_time" required>
</div>

<p><strong>Status:</strong> Available</p>

<button type="submit">Post Availability</button>
</form>
<!-- ✅ INSTRUCTIONS NOTE -->
<div class="instruction-box">
<strong>Important Instructions:</strong>
<ul>
    <li>Your profile details shown above are locked and cannot be edited here.</li>
    <li>Availability can be posted only after your previous availability time has ended.</li>
    <li>State is fixed to <b>Karnataka</b>. Please select the correct district and taluka.</li>
    <li>Your exact location is <b>not shared</b>. Only distance (in km) is shown to hospitals.</li>
    <li>Once a hospital accepts your availability, this slot will be locked.</li>
    <li>Please ensure you are reachable during the selected date and time.</li>
</ul>
</div>
 


<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCy0UN1VaNgDAMjR0oPnaleC2aidKvzd60&callback=initmap"async defer></script>
<script>
const talukas = <?= json_encode($karnataka_talukas) ?>;
const district = document.getElementById('district');
const taluka = document.getElementById('taluka');

district.addEventListener('change',()=>{
  taluka.innerHTML='<option value="">Select Taluka</option>';
  (talukas[district.value]||[]).forEach(t=>{
    taluka.innerHTML+=`<option>${t}</option>`;
  });
});

let map, marker;
function initMap(){
  const center={lat:12.9716,lng:77.5946};
  map=new google.maps.Map(document.getElementById("map"),{zoom:13,center});
  marker=new google.maps.Marker({position:center,map,draggable:true});
  setCoords(center.lat,center.lng);
  map.addListener("click",e=>{
    marker.setPosition(e.latLng);
    setCoords(e.latLng.lat(),e.latLng.lng());
  });
  marker.addListener("dragend",e=>{
    setCoords(e.latLng.lat(),e.latLng.lng());
  });
}
function setCoords(lat,lng){
  document.getElementById("latitude").value=lat;
  document.getElementById("longitude").value=lng;
}
window.onload=initMap;
</script>

<?php endif; ?>

</div>
</div>

</body>
</html>
