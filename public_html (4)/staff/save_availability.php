<?php
session_start();
require_once $_SERVER['DOCUMENT_ROOT']."/config/db.php";

$staff_id = $_SESSION['user_id'];

$check = $conn->query("
    SELECT id FROM staff_phone_verification
    WHERE staff_id=$staff_id AND verified='yes'
");

if($check->num_rows === 0){
    die("Phone verification required");
}

// SAVE AVAILABILITY (your existing logic)
$date = $_POST['date'];
$time = $_POST['time'];
$location = $_POST['location'];

$stmt = $conn->prepare("
    INSERT INTO staff_availability (staff_id, date, time, location)
    VALUES (?, ?, ?, ?)
");
$stmt->bind_param("isss", $staff_id, $date, $time, $location);
$stmt->execute();

header("Location: staff_dashboard.php?posted=1");
