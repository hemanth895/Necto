<?php
session_start();

/* ---------- REQUIRE LOGIN ---------- */
function requireLogin() {
    if (!isset($_SESSION['user_id'])) {
        header("Location: /login.php");
        exit;
    }
}

/* ---------- REQUIRE ROLE ---------- */
function requireRole($role) {
    if (!isset($_SESSION['role']) || $_SESSION['role'] !== $role) {
        header("Location: /login.php");
        exit;
    }
}
