 <?php
// Database credentials
$host = "localhost";
$user = "u864327258_adi";
$pass = "Adiex172@cet";
$db   = "u864327258_nectoin_db";

// Create connection
$conn = new mysqli($host, $user, $pass, $db);

// Check connection
if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}

// Optional: set charset (IMPORTANT)
$conn->set_charset("utf8mb4");
?>
