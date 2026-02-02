<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

 require_once __DIR__ . '/config/db.php';


$message = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $email = trim($_POST['email'] ?? '');

    if ($email === '') {
        $message = "Email is required";
    } else {
        $stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows === 1) {
            header("Location: reset_password.php?email=" . urlencode($email));
            exit;
        } else {
            $message = "Email not found";
        }
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Forgot Password</title>
    <link rel="stylesheet" href="auth.css">
</head>
<body>

<div class="auth-box">
    <h2>Forgot Password</h2>

    <?php if ($message): ?>
        <div class="message"><?= htmlspecialchars($message) ?></div>
    <?php endif; ?>

    <form method="POST">
        <input type="email" name="email" placeholder="Enter your email" required>
        <button type="submit">Continue</button>
    </form>

    <p style="text-align:center;margin-top:15px;">
        <a href="login.php">Back to Login</a>
    </p>
</div>

</body>
</html>
