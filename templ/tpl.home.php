<?php include("tpl.header.php"); ?>
<script type="text/javascript">
	g_pid = <?php eh($id); ?>;
</script>
		<h3 align="center">Light Point Docs</h3>
<div>
<?php include("tpl.menu.php"); ?>
	<div class="content-box">
		<p>Welcome!</p>
	</div>
</div>
		<br />
		<br />
<?php
	include("tpl.form-doc.php"); 
	include("tpl.footer.php"); 
?>
