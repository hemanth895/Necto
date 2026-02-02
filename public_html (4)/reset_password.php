 <?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

/* ================= DB ================= */
require_once __DIR__ . '/config/db.php';

/* ================= INPUT ================= */
$email = $_GET['email'] ?? '';
$message = "";

/* ================= BASIC VALIDATION ================= */
if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    die("Invalid reset link.");
}

/* ================= HANDLE POST ================= */
if ($_SERVER["REQUEST_METHOD"] === "POST") {

    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $message = "Invalid email";
    } elseif (strlen($password) < 6) {
        $message = "Password must be at least 6 characters";
    } else {

        $hash = password_hash($password, PASSWORD_DEFAULT);

        $stmt = $conn->prepare(
            "UPDATE users SET password = ? WHERE email = ?"
        );
        $stmt->bind_param("ss", $hash, $email);

        if ($stmt->execute() && $stmt->affected_rows === 1) {
            header("Location: login.php?reset=success");
            exit;
        } else {
            $message = "Password reset failed or email not found";
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Reset Password | Necto</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="auth.css">
</head>
<body>

<div class="auth-box">
    <h2>Reset Password</h2>

    <?php if ($message): ?>
        <div class="message">
            <?= htmlspecialchars($message) ?>
        </div>
    <?php endif; ?>

    <form method="POST" autocomplete="off">
        <input type="hidden" name="email" value="<?= htmlspecialchars($email) ?>">

        <div class="password-wrap">
            <input
                type="password"
                id="newPassword"
                name="password"
                placeholder="New Password"
                required
            >
            <span onclick="toggleNew()">👁️</span>
        </div>

        <button type="submit">Reset Password</button>
    </form>
</div>

<script>
function toggleNew() {
    const pwd = document.getElementById("newPassword");
    pwd.type = pwd.type === "password" ? "text" : "password";
}
</script>

</body>
</html>

