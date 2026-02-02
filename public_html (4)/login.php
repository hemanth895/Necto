<?php
// ---------------- ERROR REPORTING ----------------
ini_set('display_errors', 1);
error_reporting(E_ALL);

// ---------------- SESSION ----------------
session_start();

// ---------------- DB ----------------
require_once($_SERVER['DOCUMENT_ROOT'] . "/config/db.php");

$error = "";
$success = "";

if (isset($_GET['registered']) && $_GET['registered'] == 1) {
    $success = "Account created successfully. Please login.";
}

// ---------------- LOGIN LOGIC ----------------
if ($_SERVER["REQUEST_METHOD"] === "POST") {

    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($email === '' || $password === '') {
        $error = "Email and password are required";
    } else {

        $stmt = $conn->prepare("SELECT id, password, role FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result && $result->num_rows === 1) {
            $user = $result->fetch_assoc();

            if (password_verify($password, $user['password'])) {

                $_SESSION['user_id'] = $user['id'];
                $_SESSION['role']    = $user['role'];

                if ($user['role'] === 'admin') {
                    header("Location: /admin/admin_dashboard.php");
                } elseif ($user['role'] === 'hospital') {
                    header("Location: /hospital/dashboard_hospital.php");
                } elseif ($user['role'] === 'staff') {
                    header("Location: /staff/dashboard_staff.php");
                }
                exit;

            } else {
                $error = "Invalid email or password";
            }
        } else {
            $error = "Invalid email or password";
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Login | Necto</title>

<link rel="stylesheet" href="/assets/css/auth.css">

<style>
/* Back button */
.back-home {
    text-align: left;
    margin-bottom: 15px;
}

.home-btn {
    text-decoration: none;
    font-weight: bold;
    color: #0f766e;
}
</style>
</head>

<body>

<div class="auth-box">

     

    <h2>Login</h2>

    <!-- SUCCESS MESSAGE -->
    <?php if ($success): ?>
        <div style="
            background:#dcfce7;
            color:#065f46;
            padding:12px;
            border-radius:8px;
            margin-bottom:15px;
            text-align:center;
        ">
            <?= htmlspecialchars($success) ?>
        </div>
    <?php endif; ?>

    <!-- ERROR MESSAGE -->
    <?php if ($error): ?>
        <div class="message"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <!-- LOGIN FORM -->
    <form method="POST" novalidate>

        <input type="email" name="email" placeholder="Email Address" required>

        <div class="password-wrap">
            <input type="password" id="password" name="password" placeholder="Password" required>
            <span onclick="togglePassword()">👁️</span>
        </div>

        <button type="submit">Login</button>
    </form>

    <!-- LINKS -->
    <p style="text-align:center;margin-top:10px;">
        <a href="/forgot_password.php">Forgot password?</a>
    </p>

    <p style="text-align:center;margin-top:15px;">
        Don’t have an account?
        <a href="/register.php">Register</a>
        <!-- BACK TO HOME -->
    <div class="back-home">
        <a href="/" class="home-btn">← Back </a>
    </div>

    </p>

</div>

<script>
function togglePassword() {
    const pwd = document.getElementById("password");
    pwd.type = pwd.type === "password" ? "text" : "password";
}
</script>

</body>
</html>
