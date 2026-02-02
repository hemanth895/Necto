 <?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once(__DIR__ . "/config/db.php");

$message = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {

    $name     = trim($_POST['name'] ?? '');
    $email    = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    $role     = $_POST['role'] ?? '';
    $agree    = $_POST['agree_terms'] ?? '';

    if ($name === '' || $email === '' || $password === '') {
        $message = "All fields are required";
    } elseif ($role === '') {
        $message = "Please select account type";
    } elseif (!$agree) {
        $message = "You must agree to Terms & Privacy Policy";
    } else {

        $check = $conn->prepare("SELECT id FROM users WHERE email = ?");
        $check->bind_param("s", $email);
        $check->execute();
        $check->store_result();

        if ($check->num_rows > 0) {
            $message = "Email already registered";
        } else {

            $hash = password_hash($password, PASSWORD_DEFAULT);

            $stmt = $conn->prepare(
                "INSERT INTO users (name, email, role, password)
                 VALUES (?, ?, ?, ?)"
            );
            $stmt->bind_param("ssss", $name, $email, $role, $hash);

            if ($stmt->execute()) {
                header("Location: login.php?registered=1");
                exit;
            } else {
                $message = "Registration failed. Try again.";
            }
        }
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Create Account | Necto</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
        body {
            margin: 0;
            font-family: "Segoe UI", Roboto, Arial, sans-serif;
            background: linear-gradient(135deg, #0f766e, #0891b2);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .auth-card {
            background: #ffffff;
            width: 100%;
            max-width: 380px;
            padding: 32px;
            border-radius: 16px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.25);
        }

        .auth-card h2 {
            text-align: center;
            margin-bottom: 20px;
            color: #111827;
        }

        input {
            width: 100%;
            padding: 12px;
            margin-bottom: 12px;
            border-radius: 8px;
            border: 1px solid #d1d5db;
            font-size: 14px;
        }

        /* ===== FIXED RADIO ALIGNMENT ===== */
        .role-group {
            margin: 12px 0;
        }

        .role-group label {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            margin-bottom: 10px;
            cursor: pointer;
        }

        .role-group input[type="radio"] {
            width: 18px;
            height: 18px;
            accent-color: #0f766e;
        }

        /* ===== FIXED CHECKBOX ALIGNMENT ===== */
        .checkbox {
            margin: 14px 0;
        }

        .checkbox label {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            font-size: 13px;
            line-height: 1.4;
            cursor: pointer;
        }

        .checkbox input[type="checkbox"] {
            width: 18px;
            height: 18px;
            margin-top: 2px;
            accent-color: #0f766e;
        }

        .checkbox a {
            color: #0f766e;
            text-decoration: none;
            font-weight: 500;
        }

        .checkbox a:hover {
            text-decoration: underline;
        }

        button {
            width: 100%;
            padding: 12px;
            background: #0f766e;
            color: #ffffff;
            border: none;
            border-radius: 10px;
            font-size: 15px;
            cursor: pointer;
        }

        button:hover {
            background: #0b5f59;
        }

        .message {
            background: #fff3cd;
            color: #92400e;
            padding: 10px;
            border-radius: 8px;
            margin-bottom: 14px;
            font-size: 13px;
            text-align: center;
        }

        .links {
            text-align: center;
            margin-top: 14px;
            font-size: 14px;
        }

        .links a {
            color: #0f766e;
            text-decoration: none;
        }

        .links a:hover {
            text-decoration: underline;
        }
    </style>
</head>

<body>

<div class="auth-card">

    <h2>Create Account</h2>

    <?php if ($message): ?>
        <div class="message"><?= htmlspecialchars($message) ?></div>
    <?php endif; ?>

    <form method="POST">

        <input type="text" name="name" placeholder="Full Name" required>
        <input type="email" name="email" placeholder="Email Address" required>
        <input type="password" name="password" placeholder="Create Password" required>

        <div class="role-group">
            <label>
                <input type="radio" name="role" value="hospital" required>
                <span>Hospital</span>
            </label>
            <label>
                <input type="radio" name="role" value="staff" required>
                <span>Paramedical Staff</span>
            </label>
        </div>

        <div class="checkbox">
            <label>
                <input type="checkbox" name="agree_terms" value="1" required>
                <span>
                    I agree to
                    <a href="terms.php" target="_blank">Terms & Conditions</a>
                    and
                    <a href="privacy.php" target="_blank">Privacy Policy</a>
                </span>
            </label>
        </div>

        <button type="submit">Register</button>

    </form>

    <div class="links">
        Already have an account?
        <a href="login.php">Login</a><br><br>
        <a href="/">← Back</a>
    </div>

</div>

</body>
</html>
