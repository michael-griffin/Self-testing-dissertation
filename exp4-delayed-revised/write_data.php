<?php
//Original method
$filename = $_POST['filename'];
$data = $_POST['filedata'];
 
//If you switch to the below, will successfully write to blah.txt
//$filename = "blah.txt";
//$data = "asd";

//file put contents equivalent to fopen fwrite fclose in succession. FILE_APPEND an optional param.
//FILE_APPEND used so when writing to subjects.txt, does not overwrite what's already there.
//PHP_EOL adds an end line character that should work cross operating system, again for subjects.txt
file_put_contents($filename, $data.PHP_EOL, FILE_APPEND);
?>