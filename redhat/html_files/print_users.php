<?php

$servername = "16.171.3.0"; 
$database   = "iti";   
$username   = "iti";     
$password   = "iti";     
//$table      = "userinfo";

// Create connection (MySQLi Procedural)
$conn = mysqli_connect($servername, $username, $password, $database);

// Check connection
if (!$conn) {
  die("Connection failed: " . mysqli_connect_error());
}
//echo "<br> Connected successfully <br><br>";


$print_users_query = "select * from userinfo";
$print_users = mysqli_query($conn, $print_users_query);

echo "<h4>previously registered users: </h4>";

if (mysqli_num_rows($print_users) > 0) {
        // output data of each row
        while($row = mysqli_fetch_assoc($print_users)) {
          echo " - Name: '" . $row["firstname"] . " " . $row["lastname"]  . "<br>";
        }
      } else {
        echo "0 results";
      }
      

?>