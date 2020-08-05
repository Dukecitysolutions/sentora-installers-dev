-- save current setting of sql_mode
SET @old_sql_mode := @@sql_mode ;

-- derive a new value by removing NO_ZERO_DATE and NO_ZERO_IN_DATE
SET @new_sql_mode := @old_sql_mode ;
SET @new_sql_mode := TRIM(BOTH ',' FROM REPLACE(CONCAT(',',@new_sql_mode,','),',NO_ZERO_DATE,'  ,','));
SET @new_sql_mode := TRIM(BOTH ',' FROM REPLACE(CONCAT(',',@new_sql_mode,','),',NO_ZERO_IN_DATE,',','));
SET @@sql_mode := @new_sql_mode ;

USE `sentora_postfix`;

ALTER TABLE admin MODIFY COLUMN created datetime DEFAULT NULL;
ALTER TABLE admin MODIFY COLUMN modified datetime DEFAULT NULL;

ALTER TABLE alias MODIFY COLUMN created datetime DEFAULT NULL;
ALTER TABLE alias MODIFY COLUMN modified datetime DEFAULT NULL;

ALTER TABLE alias_domain MODIFY COLUMN created datetime DEFAULT NULL;
ALTER TABLE alias_domain MODIFY COLUMN modified datetime DEFAULT NULL;

ALTER TABLE alias_domain MODIFY COLUMN created datetime DEFAULT NULL;
ALTER TABLE alias_domain MODIFY COLUMN modified datetime DEFAULT NULL;

ALTER TABLE domain MODIFY COLUMN created datetime DEFAULT NULL;
ALTER TABLE domain MODIFY COLUMN modified datetime DEFAULT NULL;

ALTER TABLE mailbox MODIFY COLUMN created datetime DEFAULT NULL;
ALTER TABLE mailbox MODIFY COLUMN modified datetime DEFAULT NULL;

ALTER TABLE vacation MODIFY COLUMN created datetime DEFAULT NULL;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;