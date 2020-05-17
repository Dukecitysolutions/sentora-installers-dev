GRANT ALL PRIVILEGES ON sentora_postfix .* TO 'postfix'@'localhost';
GRANT ALL PRIVILEGES ON sentora_proftpd .* TO 'proftpd'@'localhost';
GRANT ALL PRIVILEGES ON sentora_roundcube .* TO 'roundcube'@'localhost';

ALTER TABLE `zpanel_core`.`x_accounts` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_aliases` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_bandwidth` 
  DROP PRIMARY KEY, 
  ADD PRIMARY KEY(`bd_id_pk`);

ALTER TABLE `zpanel_core`.`x_distlists` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_distlistusers` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_dns` 
  CHANGE COLUMN dn_target_vc dn_target_vc varchar(255) NULL, 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_faqs` 
  DROP PRIMARY KEY, 
  ADD PRIMARY KEY(`fq_id_pk`), 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_forwarders` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_ftpaccounts` 
  CHANGE COLUMN ft_user_vc ft_user_vc varchar(50) NULL;

ALTER TABLE `zpanel_core`.`x_logs` 
  DROP PRIMARY KEY, 
  ADD PRIMARY KEY(`lg_id_pk`), 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_mailboxes` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_modcats` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_modules` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_packages` 
  DROP COLUMN pk_enablecgi_in, 
  CHANGE COLUMN pk_created_ts pk_created_ts int(30) NULL, 
  CHANGE COLUMN pk_deleted_ts pk_deleted_ts int(30) NULL AFTER pk_created_ts;

ALTER TABLE `zpanel_core`.`x_permissions` 
  DROP PRIMARY KEY, 
  ADD PRIMARY KEY(`pe_id_pk`);

ALTER TABLE `zpanel_core`.`x_profiles` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_settings` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_translations` 
COLLATE=utf8_general_ci;

ALTER TABLE `zpanel_core`.`x_vhosts` 
  ADD COLUMN vh_soaserial_vc char(10) NULL DEFAULT 'AAAAMMDDSS' AFTER vh_portforward_in;

CREATE TABLE `zpanel_core`.`x_htpasswd_file` (
  `x_htpasswd_file_id` int(11) NOT NULL AUTO_INCREMENT,
  `x_htpasswd_file_target` varchar(255) NOT NULL,
  `x_htpasswd_file_message` varchar(255) NOT NULL,
  `x_htpasswd_file_created` int(11) NOT NULL,
  `x_htpasswd_file_deleted` int(11) DEFAULT NULL,
  `x_htpasswd_sentora_user_id` int(11) NOT NULL,
  PRIMARY KEY (`x_htpasswd_file_id`),
  UNIQUE KEY `x_htpasswd_file_target` (`x_htpasswd_file_target`),
  KEY `x_htpasswd_file_x_htpasswd_sentora_user_id_idx` (`x_htpasswd_sentora_user_id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `zpanel_core`.`x_htpasswd_mapper` (
  `x_htpasswd_mapper_id` int(11) NOT NULL AUTO_INCREMENT,
  `x_htpasswd_file_id` int(11) NOT NULL,
  `x_htpasswd_user_id` int(11) NOT NULL,
  PRIMARY KEY (`x_htpasswd_mapper_id`),
  KEY `x_htpasswd_mapper_x_htpasswd_file_id_idx` (`x_htpasswd_file_id`),
  KEY `x_htpasswd_mapper_x_htpasswd_user_id_idx` (`x_htpasswd_user_id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `zpanel_core`.`x_htpasswd_user` (
  `x_htpasswd_user_id` int(11) NOT NULL AUTO_INCREMENT,
  `x_htpasswd_user_username` varchar(255) NOT NULL,
  `x_htpasswd_user_password` varchar(255) NOT NULL,
  `x_htpasswd_user_created` int(11) NOT NULL,
  `x_htpasswd_user_deleted` int(11) DEFAULT NULL,
  `x_htpasswd_sentora_user_id` int(11) NOT NULL,
  PRIMARY KEY (`x_htpasswd_user_id`),
  UNIQUE KEY `x_htpasswd_user_username` (`x_htpasswd_user_username`),
  UNIQUE KEY `x_htpasswd_user_password` (`x_htpasswd_user_password`)
) DEFAULT CHARSET=utf8;



CREATE DATABASE sentora_core;
CREATE DATABASE sentora_postfix;
CREATE DATABASE sentora_proftpd;
CREATE DATABASE sentora_roundcube;