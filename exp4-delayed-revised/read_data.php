<?php
//Original method
$filename = $_POST['filename'];
//$data = $_POST['filedata'];

$myfile = fopen($filename, "r");
echo fread($myfile,filesize("subjects.txt"));
fclose($myfile);

?>