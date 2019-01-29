<?php if(!defined("Z_PROTECTED")) exit; ?>
<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<meta http-equiv="X-UA-Compatible" content="IE=edge" />
		<title>NetBackup DB report</title>
		<link type="text/css" href="templ/pikaday.css" rel="stylesheet" />
		<link type="text/css" href="templ/style.css" rel="stylesheet" />
		<?php if($uid) { ?>
		<script src="nbt.js"></script>
		<?php } ?>
	</head>
	<body>
		<?php if($uid) { ?>
		<ul class="menu-bar">
			<li><a href="<?php eh("$self"); ?>">Home</a></li>
			<li><a href="?action=all">All images</a></li>
			<ul style="float:right;list-style-type:none;">
				<?php if($uid) { ?>
				<li><a href="?action=logoff">Log Out</a></li>
				<?php } else { ?>
				<li><a href="?action=login">Log In</a></li>
				<?php } ?>
			</ul>
		</ul>
		<?php } ?>
