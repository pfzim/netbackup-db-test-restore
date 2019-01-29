<?php include("tpl.header.php"); ?>
<script type="text/javascript">
	g_pid = <?php eh($id); ?>;
</script>
		<h3 align="center">NetBackup DB images list</h3>
<div>
	<div class="content-box">
		<table id="table" class="main-table" width="100%">
			<thead>
			<tr>
				<th width="14%">Date</th>
				<th width="16%">DB</th>
				<th width="14%">Policy</th>
				<th width="14%">Schedule</th>
				<th width="14%">Client</th>
				<th width="14%">Media</th>
				<th width="14%">Status</th>
			</tr>
			</thead>
			<tbody id="table-data">
		<?php $i = 0; foreach($images as &$row) { $i++; ?>
			<tr id="<?php eh("row".$row['id']); ?>" data-id=<?php eh($row['id']);?>>
				<td><?php eh($row['date']); ?></td>
				<td><?php eh($row['db']); ?></td>
				<td><?php eh($row['policy_name']); ?></td>
				<td><?php eh($row['sched_label']); ?></td>
				<td><?php eh($row['client_name']); ?></td>
				<td><?php eh($row['media_list']); ?></td>
				<td><?php echo bit_to_string($g_flag_html, $row['flags']); ?></td>
				<?php if($uid) { ?>
				<td>
					<span class="command" onclick="f_menu(event);">Menu</span>
				</td>
				<?php } ?>
			</tr>
		<?php } ?>
			</tbody>
		</table>
	</div>
</div>
		<br />
		<br />
<?php include("tpl.menu-nbt.php"); ?>
<?php include("tpl.footer.php"); ?>
