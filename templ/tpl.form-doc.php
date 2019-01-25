<?php if(!defined("Z_PROTECTED")) exit; ?>
		<div id="document-container" class="modal-container" style="display: none">
			<span class="close white" onclick="this.parentNode.style.display='none'">&times;</span>
			<div class="modal-content">
				<span class="close" onclick="this.parentNode.parentNode.style.display='none'">&times;</span>
				<form id="document">
				<h3>Создать документ</h3>
				<input name="id" type="hidden" value=""/>
				<input name="pid" type="hidden" value=""/>
				<div class="form-title"><label for="reg_upr">Региональное управление*:</label></div>
				<select class="form-field" id="reg_upr" name="reg_upr">
				<?php for($i = 1; $i < count($g_doc_reg_upr); $i++) { ?>
					<option value="<?php eh($i); ?>"><?php eh($g_doc_reg_upr[$i]); ?></option>
				<?php } ?>
				</select>
				<div id="reg_upr-error" class="form-error"></div>
				<div class="form-title">Региональное отделение*:</div>
				<select class="form-field" name="reg_otd">
				<?php for($i = 1; $i < count($g_doc_reg_otd); $i++) { ?>
					<option value="<?php eh($i); ?>"><?php eh($g_doc_reg_otd[$i]); ?></option>
				<?php } ?>
				</select>
				<div id="reg_otd-error" class="form-error"></div>
				<div class="form-title"><label for="bis_unit">Бизнес юнит*:</label></div>
				<input class="form-field" id="bis_unit" name="bis_unit" type="edit" value=""/>
				<div id="bis_unit-error" class="form-error"></div>
				<div class="form-title">Тип документа*:</div>
				<span><input id="doc_type_1" name="doc_type_1" type="checkbox" value="1"/><label for="doc_type_1">Торг12</label></span>
				<span><input id="doc_type_2" name="doc_type_2" type="checkbox" value="1"/><label for="doc_type_2">СФ</label></span>
				<span><input id="doc_type_3" name="doc_type_3" type="checkbox" value="1"/><label for="doc_type_3">1Т</label></span>
				<span><input id="doc_type_4" name="doc_type_4" type="checkbox" value="1"/><label for="doc_type_4">Доверенность</label></span>
				<br />
				<span><input id="doc_type_5" name="doc_type_5" type="checkbox" value="1"/><label for="doc_type_5">Справка А</label></span>
				<span><input id="doc_type_6" name="doc_type_6" type="checkbox" value="1"/><label for="doc_type_6">Справка Б</label></span>
				<div id="doc_type_1-error" class="form-error"></div>
				<div class="form-title"><label for="order">Номер ордера*:</label></div>
				<input class="form-field" id="order" name="order" type="edit" value=""/>
				<div id="order-error" class="form-error"></div>
				<div class="form-title"><label for="order_date">Дата ордера*:</label></div>
				<input class="form-field" id="order_date" name="order_date" type="edit" value=""/>
				<div id="order_date-error" class="form-error"></div>
				<div class="form-title"><label for="contr_name">Наименование контрагента*:</label></div>
				<input class="form-field" id="contr_name" name="contr_name" type="edit" value=""/>
				<div id="contr_name-error" class="form-error"></div>
				<div class="form-title">Статус документа*:</div>
				<select class="form-field" name="status">
				<?php for($i = 1; $i < count($g_doc_status); $i++) { ?>
					<option value="<?php eh($i); ?>"><?php eh($g_doc_status[$i]); ?></option>
				<?php } ?>
				</select>
				<div id="status-error" class="form-error"></div>
				<div class="form-title"><label for="info">Описание:</label></div>
				<input class="form-field" id="info" name="info" type="edit" value=""/><br />
				<div id="info-error" class="form-error"></div>
				<div class="f-right">
					<button class="button-accept" type="submit" onclick="return f_save('document');">Сохранить</button>
					&nbsp;
					<button class="button-decline" type="button" onclick="this.parentNode.parentNode.parentNode.parentNode.style.display='none'">Отмена</button>
				</div>
				</form>
			</div>
		</div>
<script src="moment.js"></script>
<script src="pikaday.js"></script>
<script>
    var picker = new Pikaday({
        field: document.getElementById('order_date'),
        format: 'DD.MM.YYYY',
    });
</script>
