DROP TABLE IF EXISTS `nbt`.`nbt_access`;
CREATE TABLE  `nbt`.`nbt_access` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `dn` varchar(1024) NOT NULL DEFAULT '',
  `oid` int(10) unsigned NOT NULL DEFAULT '0',
  `allow_bits` binary(32) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `nbt`.`nbt_images`;
CREATE TABLE  `nbt`.`nbt_images` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `policy_name` varchar(255) NOT NULL,
  `sched_label` varchar(255) NOT NULL,
  `client_name` varchar(255) NOT NULL,
  `backup_time` bigint(20) unsigned NOT NULL,
  `expiration` bigint(20) unsigned NOT NULL,
  `backupid` varchar(255) NOT NULL,
  `ss_name` varchar(255) NOT NULL,
  `media_list` varchar(4096) NOT NULL,
  `nbimage` varchar(255) NOT NULL,
  `db` varchar(255) NOT NULL,
  `stripes` int(10) unsigned NOT NULL,
  `mdfs` varchar(255) NOT NULL,
  `logs` varchar(4096) NOT NULL,
  `flags` int(10) unsigned NOT NULL DEFAULT '0',
  `date2` varchar(255) NOT NULL,
  `restore_date` datetime NOT NULL,
  `duration` int(10) unsigned NOT NULL DEFAULT '0',
  `dbsize` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nbimage` (`nbimage`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `nbt`.`nbt_media`;
CREATE TABLE  `nbt`.`nbt_media` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `media_id` varchar(45) NOT NULL,
  `media_label` varchar(45) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `nbt`.`nbt_users`;
CREATE TABLE  `nbt`.`nbt_users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(1024) NOT NULL DEFAULT '',
  `sid` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
