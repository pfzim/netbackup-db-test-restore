<?php
/*
    light-point-docs
    Copyright (C) 2018 Dmitry V. Zimin

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

if(!file_exists('inc.config.php'))
{
	header('Location: install.php');
	exit;
}

	require_once("inc.config.php");

$g_flag_names = array("WAITING FOR TEST", "OK", "CHECKDB FAILED", "RESTORE FAILED", "TESTING IN PROGRESS", "NOT FOUND");
$g_flag_html = array('<nobr><span class="warn">WAITING FOR TEST</span></nobr>', '<nobr><span class="pass">OK</span></nobr>', '<nobr><span class="error">CHECKDB FAILED</span></nobr>', '<nobr><span class="error">RESTORE FAILED</span></nobr>', '<nobr><span class="warn">TESTING IN PROGRESS</span></nobr>', '<nobr><span class="error">NOT FOUND</span></nobr>');

function bits_to_array($flag_names, $flag)
{
	$result = array();
	for($i = 0; $i < count($flag_names); $i++)
	{
		if(($flag >> $i) & 0x01)
		{
			$result[] = &$flag_names[$i];
		}
	}
	return $result;
}

	session_name("ZID");
	session_start();
	error_reporting(E_ALL);
	define("Z_PROTECTED", "YES");

	$self = $_SERVER['PHP_SELF'];

	if(!empty($_SERVER['HTTP_CLIENT_IP'])) {
		$ip = $_SERVER['HTTP_CLIENT_IP'];
	} elseif(!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
		$ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
	} else {
		$ip = @$_SERVER['REMOTE_ADDR'];
	}

	require_once('inc.db.php');
	require_once('inc.ldap.php');
	require_once('inc.access.php');
	require_once('inc.rights.php');
	require_once('inc.utils.php');

	$action = "";
	if(isset($_GET['action']))
	{
		$action = $_GET['action'];
	}

	$id = 0;
	if(isset($_GET['id']))
	{
		$id = $_GET['id'];
	}

	if($action == "message")
	{
		switch($id)
		{
			case 1:
				$error_msg = "Registration is complete. Wait for the administrator to activate your account.";
				break;
			default:
				$error_msg = "Unknown error";
				break;
		}

		include('templ/tpl.message.php');
		exit;
	}

	$db = new MySQLDB(DB_RW_HOST, NULL, DB_USER, DB_PASSWD, DB_NAME, DB_CPAGE, TRUE);
	$ldap = new LDAP(LDAP_HOST, LDAP_PORT, LDAP_USER, LDAP_PASSWD, FALSE);

	$uid = 0;
	$user_login = NULL;
	if(isset($_SESSION['uid']) && isset($_SESSION['login']))
	{
		$uid = $_SESSION['uid'];
		$user_login = $_SESSION['login'];
	}

	if(empty($uid))
	{
		if(!empty($_COOKIE['zh']) && !empty($_COOKIE['zl']))
		{
			if($db->select(rpv("SELECT m.`id`, m.`login` FROM @users AS m WHERE m.`login` = ! AND m.`sid` IS NOT NULL AND m.`sid` = ! LIMIT 1", $_COOKIE['zl'], $_COOKIE['zh'])))
			{
				$_SESSION['uid'] = $db->data[0][0];
				$_SESSION['login'] = $db->data[0][1];
				$uid = $_SESSION['uid'];
				$user_login = $_SESSION['login'];
				setcookie("zh", $_COOKIE['zh'], time()+2592000, '/');
				setcookie("zl", $_COOKIE['zl'], time()+2592000, '/');
			}
		}
	}

	$user_perm = new UserPermissions($db, $ldap, $user_login);

	if(empty($uid))
	{
		switch($action)
		{
			case 'logon':
			{
				if(empty($_POST['login']) || empty($_POST['passwd']))
				{
					$error_msg = "Неверное имя пользователя или пароль!";
					include('templ/tpl.login.php');
					exit;
				}

				$login = @$_POST['login'];

				if(strpos($login, '\\'))
				{
					list($domain, $login) = explode('\\', $login, 2);
				}
				else if(strpos($login, '@'))
				{
					list($login, $domain) = explode('@', $login, 2);
				}
				else
				{
					$error_msg = "Неверный формат логина (user@domain, domain\\user)!";
					include('templ/tpl.login.php');
					exit;
				}

				if(!$ldap->reset_user($login.'@'.$domain, @$_POST['passwd'], TRUE))
				{
					$error_msg = "Неверное имя пользователя или пароль!";
					include('templ/tpl.login.php');
					exit;
				}

				if($db->select(rpv("SELECT m.`id` FROM `@users` AS m WHERE m.`login` = ! LIMIT 1", $login)))
				{
					$_SESSION['uid'] = $db->data[0][0];
				}
				else // add new LDAP user
				{
					$db->put(rpv("INSERT INTO @users (login) VALUES (!)", $login));
					$_SESSION['uid'] = $db->last_id();
				}

				$_SESSION['login'] = $login;
				$uid = $_SESSION['uid'];
				$user_login = $_SESSION['login'];

				$sid = uniqid();
				setcookie("zh", $sid, time()+2592000, '/');
				setcookie("zl", $login, time()+2592000, '/');

				$db->put(rpv("UPDATE @users SET `sid` = ! WHERE `id` = # LIMIT 1", $sid, $uid));

				header('Location: '.$self);
				exit;
			}
			
			case 'login':
			{
				include('templ/tpl.login.php'); // show login form
				exit;
			}
		}
	}

	if(!$uid)
	{
		////include('templ/tpl.login.php'); // show login form
		//header('Location: '.$self.'?action=login');
		//exit;
	}

	switch($action)
	{
		case 'logoff':
		{
			$db->put(rpv("UPDATE @users SET `sid` = NULL WHERE `id` = # LIMIT 1", $uid));
			$_SESSION['uid'] = 0;
			$_SESSION['login'] = NULL;
			$uid = $_SESSION['uid'];
			$user_login = $_SESSION['login'];
			$user_perm->reset_user();
			setcookie("zh", NULL, time()-60, '/');
			setcookie("zl", NULL, time()-60, '/');
			
			header('Location: '.$self);
		}
		exit;

		case 'unmark':
		{
			header("Content-Type: text/plain; charset=utf-8");
			if(!$uid)
			{
				echo '{"code": 1, "message": "Please, log in"}';
				exit;
			}

			$db->put(rpv("UPDATE `@images` SET `flags` = `flags` & 0xFFFFFFFE WHERE `id` = # LIMIT 1", $id));

			echo '{"code": 0, "message": "Operation successful (ID '.$id.')"}';
		}
		exit;

		case 'mark':
		{
			header("Content-Type: text/plain; charset=utf-8");
			if(!$uid)
			{
				echo '{"code": 1, "message": "Please, log in"}';
				exit;
			}

			$db->put(rpv("UPDATE `@images` SET `flags` = `flags` | 0x01 WHERE `id` = # LIMIT 1", $id));

			echo '{"code": 0, "message": "Operation successful (ID '.$id.')"}';
		}
		exit;

		case 'export':
		{
			header("Content-Type: text/plain; charset=utf-8");
			header("Content-Disposition: attachment; filename=\"images.json\"; filename*=utf-8''images.json");

			if($db->select_assoc_ex($config, rpv("SELECT m.`value` FROM @config AS m WHERE m.`name` = 'last_update'"))
			&& $db->select_assoc_ex($images, rpv("SELECT m.`id`, m.`backupid`, m.`nbimage`, DATE_FORMAT(FROM_UNIXTIME(m.`backup_time`), '%d.%m.%Y %H:%i:%s') AS `bk_date`, DATE_FORMAT(FROM_UNIXTIME(m.`expiration`), '%d.%m.%Y %H:%i:%s') AS `ex_date`, m.`db`, m.`policy_name`, m.`sched_label`, m.`client_name`, m.`media_list`, m.`dbsize`, DATE_FORMAT(m.`restore_date`, '%d.%m.%Y %H:%i:%s') AS `rs_date`, m.`duration`, m.`flags`, m.`stripes`, m.`mdfs`, m.`logs`, m.`ss_name` FROM @images AS m ORDER BY m.`backup_time` DESC"))
			)
			{
				$result_json = array(
					'code' => 0,
					'message' => 'OK',
					'last_update' => $config[0]['value'],
					'images' => &$images
				);
			}
			else
			{
				$result_json = array(
					'code' => 1,
					'message' => $db->get_last_error()
				);
			}

			echo json_encode($result_json, JSON_PRETTY_PRINT);
		}
		exit;
		
		case 'all':
		{
			/*
			if(!$user_perm->check_permission($id, LPD_ACCESS_READ))
			{
				$error_msg = "Access denied to section ".$id." for user ".$uid."!";
				include('templ/tpl.message.php');
				exit;
			}
			*/

			header("Content-Type: text/html; charset=utf-8");

			$db->select_assoc_ex($images, rpv("SELECT m.`id`, DATE_FORMAT(FROM_UNIXTIME(m.`backup_time`), '%d.%m.%Y') AS `bk_date`, m.`db`, m.`policy_name`, m.`sched_label`, m.`client_name`, m.`media_list`, m.`dbsize`, DATE_FORMAT(m.`restore_date`, '%d.%m.%Y') AS `rs_date`, m.`duration`, m.`flags` FROM @images AS m ORDER BY m.`backup_time` DESC"));
			include('templ/tpl.main.php');
		}
		exit;

		case '':
		{
			/*
			if(!$user_perm->check_permission($id, LPD_ACCESS_READ))
			{
				$error_msg = "Access denied to section ".$id." for user ".$uid."!";
				include('templ/tpl.message.php');
				exit;
			}
			*/

			header("Content-Type: text/html; charset=utf-8");

			$db->select_assoc_ex($images, rpv("SELECT m.`id`, DATE_FORMAT(FROM_UNIXTIME(m.`backup_time`), '%d.%m.%Y') AS `bk_date`, m.`db`, m.`policy_name`, m.`sched_label`, m.`client_name`, m.`media_list`, m.`dbsize`, DATE_FORMAT(m.`restore_date`, '%d.%m.%Y') AS `rs_date`, m.`duration`, m.`flags` FROM @images AS m WHERE m.`flags` & 0xFFFFFFDF ORDER BY m.`backup_time` DESC"));
			include('templ/tpl.main.php');
		}
		exit;

		default:
		{
			$error_msg = "Unknown action: ".$action."!";
			include('templ/tpl.message.php');
			exit;
		}
	}
