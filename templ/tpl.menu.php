<?php if(!defined("Z_PROTECTED")) exit; ?>
	<div class="left-menu">
		<ul>
		<?php $i = 0; foreach($sections as &$row) { $i++; ?>
		<li<?php if($id == $row[0]) { echo ' class="active"'; } ?>><a href="?id=<?php eh($row[0]); ?>"><?php eh($row[1]); ?></a></li>
		<?php } ?>
		</ul>
	</div>
