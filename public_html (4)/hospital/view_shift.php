<?php
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/db.php";
require_once $_SERVER['DOCUMENT_ROOT'] . "/config/auth.php";

requireLogin();
requireRole('hospital');

$shift_id = intval($_GET['id']);
$hospital_id = $_SESSION['user_id'];

/* Fetch shift */
$stmt = $conn->prepare("
  SELECT * FROM hospital_shifts
  WHERE id=? AND hospital_id=?
");
$stmt->bind_param("ii", $shift_id, $hospital_id);
$stmt->execute();
$shift = $stmt->get_result()->fetch_assoc();

if (!$shift) die("Invalid shift");

/* Check if already assigned */
$assigned = $conn->prepare("
  SELECT sr.*, sp.full_name, sp.mobile, sp.email
  FROM shift_requests sr
  JOIN staff_profiles sp ON sp.user_id = sr.staff_id
  WHERE sr.shift_id=? AND sr.status='accepted'
");
$assigned->bind_param("i", $shift_id);
$assigned->execute();
$accepted = $assigned->get_result()->fetch_assoc();
