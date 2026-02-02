 <?php
$curl = curl_init();

curl_setopt_array($curl, [
    CURLOPT_URL => "https://www.fast2sms.com/dev/bulk",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode([
        "route" => "otp",
        "variables_values" => "123456",
        "numbers" => "91XXXXXXXXXX"
    ]),
    CURLOPT_HTTPHEADER => [
        "authorization: YOUR_API_KEY",
        "accept: application/json",
        "content-type: application/json"
    ],
]);

$response = curl_exec($curl);
curl_close($curl);

echo $response;
