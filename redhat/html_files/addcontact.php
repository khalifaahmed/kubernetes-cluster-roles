<?php

if(isset($_POST['firstname'], $_POST['lastname'], $_POST['age'], $_POST['email'])){
session_start();
$firstname = $_POST['firstname'];
$lastname  = $_POST['lastname'];
$age = $_POST['age'];
$email = $_POST['email'];

$_SESSION['firstname'] = $firstname;  
$_SESSION['lastname'] = $lastname; 
$_SESSION['age'] = $age;
$_SESSION['email'] = $email;
//}

//echo "<br> Hello  '$firstname $lastname', your age is $age & your email is '$email'<br>";

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

$query_1 = "insert into userinfo (firstname, lastname, age, email) values ('$firstname', '$lastname', $age, '$email')";
$query_2 = "select * from userinfo";
$query_3 = "select * from userinfo  order by id desc limit 1";

$result_1 = mysqli_query($conn, $query_1);  // in this method --> this line is a must to deal with db man
$result_2 = mysqli_query($conn, $query_2);
$result_3 = mysqli_query($conn, $query_3);

$_SESSION['result_2'] = $result_2;

if (mysqli_num_rows($result_3) > 0) {
  // output data of each row
  while($row = mysqli_fetch_assoc($result_3)) {
    echo "<br>A new record has been submitted successfully <br>";
    echo " - Name: '" . $row["firstname"] . " " . $row["lastname"]  . "' , Age : " . $row["age"] . " , email : " .  $row["email"] . "<br>";
  }
} else {
  echo "0 results";
}

echo '<br>' . 'Number of registered users so far (# of db_rows) = ' . mysqli_num_rows($result_2) . '<br>';

echo "<br>";
echo "<a href='print_users.php'>see other users : </a> <br>";

$conn->close();

}

?>

<br>
<a href="index.html">submit another user</a>