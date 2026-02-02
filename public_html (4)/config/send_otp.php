  <?php
// Endpoint to request an OTP (AUTOGEN)
session_start();

require_once $_SERVER['DOCUMENT_ROOT'] . '/config/sms.php'; // must define TWOFACTOR_API_KEY
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'msg' => 'Method not allowed']);
    exit;
}

if (!isset($_POST['mobile'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'msg' => 'Mobile missing']);
    exit;
}

$raw = preg_replace('/\D+/', '', $_POST['mobile']); // keep digits only

if ($raw === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'msg' => 'Invalid mobile']);
    exit;
}

// Normalize Indian 10-digit numbers by prepending country code 91
if (strlen($raw) === 10 && preg_match('/^[6-9]\d{9}$/', $raw)) {
    $mobile = '91' . $raw;
} elseif (strlen($raw) >= 11 && strlen($raw) <= 15) {
    // assume includes country code
    $mobile = $raw;
} else {
    http_response_code(400);
    echo json_encode(['success' => false, 'msg' => 'Invalid mobile format']);
    exit;
}

$apiKey = defined('TWOFACTOR_API_KEY') ? TWOFACTOR_API_KEY : '';
if (empty($apiKey)) {
    error_log('TWOFACTOR_API_KEY not defined in config/sms.php');
    http_response_code(500);
    echo json_encode(['success' => false, 'msg' => 'Server configuration error']);
    exit;
}

// Build AUTOGEN URL
$url = "https://2factor.in/API/V1/" . urlencode($apiKey) . "/SMS/" . urlencode($mobile) . "/AUTOGEN";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 20);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

$response = curl_exec($ch);
$curlErr = null;
if ($response === false) {
    $curlErr = curl_error($ch);
}
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// Log response for debugging
$logLine = sprintf("[%s] request_otp ip=%s mobile=%s http=%s curl_err=%s resp=%s\n",
    date('Y-m-d H:i:s'),
    $_SERVER['REMOTE_ADDR'] ?? 'cli',
    $mobile,
    $httpCode,
    $curlErr ?? '-',
    substr($response ?? '', 0, 1000)
);
file_put_contents(__DIR__ . '/2factor_request_log.txt', $logLine, FILE_APPEND);

if ($response === false) {
    http_response_code(502);
    echo json_encode(['success' => false, 'msg' => 'Network error while sending OTP', 'error' => $curlErr]);
    exit;
}

$data = json_decode($response, true);
if (!is_array($data) || !isset($data['Status'])) {
    http_response_code(502);
    echo json_encode(['success' => false, 'msg' => 'Invalid API response', 'raw' => $response]);
    exit;
}

if ($data['Status'] !== 'Success') {
    http_response_code(400);
    echo json_encode(['success' => false, 'msg' => 'OTP provider rejected request', 'api' => $data]);
    exit;
}

// Save session details for later verification
$_SESSION['otp_session_id'] = $data['Details'] ?? '';
$_SESSION['otp_mobile'] = $mobile;

echo json_encode(['success' => true, 'msg' => 'OTP sent', 'session_id' => $_SESSION['otp_session_id']]);
exit;
?>

