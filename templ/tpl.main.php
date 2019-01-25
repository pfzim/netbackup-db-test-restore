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
				<th width="15%">Date</th>
				<th width="15%">DB</th>
				<th width="15%">Policy</th>
				<th width="15%">Schedule</th>
				<th width="15%">Client</th>
				<th width="15%">Status</th>
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
				<td><?php eh($row['flags']); ?></td>
			</tr>
		<?php } ?>
			</tbody>
		</table>
	</div>
</div>
		<br />
		<br />
<?php
	include("tpl.footer.php");
?>
