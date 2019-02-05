<?php include("tpl.header.php"); ?>
<script type="text/javascript">
	g_pid = <?php eh($id); ?>;
</script>
		<h3 align="center">NetBackup DB images</h3>
<div>
	<div class="content-box">
		<table id="table" class="main-table" width="100%">
			<thead>
			<tr>
				<th width="5%">Backup Date</th>
				<th width="20%">DB</th>
				<th width="15%">Policy</th>
				<th width="5%">Schedule</th>
				<th width="15%">Client</th>
				<th width="10%">Media</th>
				<th width="5%">Size</th>
				<th width="5%">Restore Date</th>
				<th width="5%">Duration</th>
				<th width="10%">Status</th>
				<?php if($uid) { ?>
					<th width="5%">Operations</th>
				<?php } ?>
			</tr>
			</thead>
			<tbody id="table-data">
		<?php $i = 0; foreach($images as &$row) { $i++; ?>
			<tr id="<?php eh("row".$row['id']); ?>" data-id=<?php eh($row['id']);?>>
				<td><?php eh($row['bk_date']); ?></td>
				<td><?php eh($row['db']); ?></td>
				<td><?php eh($row['policy_name']); ?></td>
				<td><?php eh($row['sched_label']); ?></td>
				<td><?php eh($row['client_name']); ?></td>
				<td><?php eh($row['media_list']); ?></td>
				<td><?php eh(formatBytes($row['dbsize'], 0)); ?></td>
				<td><?php eh($row['rs_date']); ?></td>
				<td><?php eh(sprintf("%02d:%02d", intval($row['duration']/60), intval($row['duration']%60))); ?></td>
				<td><?php echo implode(bits_to_array($g_flag_html, $row['flags']), ' '); ?></td>
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
