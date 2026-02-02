 <?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$conn = new mysqli(
  "localhost",
  "u864327258_adi",
  "Adiex172@cet",
  "u864327258_nectoin_db"
);

if ($conn->connect_error) {
  die("DB ERROR: " . $conn->connect_error);
}

$message = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {

  $name = $_POST['name'] ?? '';
  $email = $_POST['email'] ?? '';
  $password = $_POST['password'] ?? '';
  $role = $_POST['role'] ?? '';
  $terms = $_POST['agree_terms and conditions'] ?? '';

  if (!$terms) {
    $message = "Accept terms and conditions.";
  } else {
    $hash = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $conn->prepare(
      "INSERT INTO users (name,email,password,role) VALUES (?,?,?,?)"
    );
    $stmt->bind_param("ssss", $name, $email, $hash, $role);
    $stmt->execute();
    $message = "Registered successfully";
  }
}
?>

<!DOCTYPE html>
<html>
<body>
<form method="POST">
  <input name="name" placeholder="Name" required>
  <input name="email" type="email" required>
  <input name="password" type="password" required>

  <select name="role" required>
    <option value="staff">Staff</option>
    <option value="hospital">Hospital</option>
  </select>

  <label>
    <input type="checkbox" name="agree_terms and conditions" required> Agree
  </label>

  <button type="submit">Register</button>
</form>

<p><?= $message ?></p>
</body>
</html>
