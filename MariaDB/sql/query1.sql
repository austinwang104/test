select * from ehrms2.eip_edEmp_profile; -- 員工自我維護檔(新問候語,問候語大頭貼)
select * from information_schema.columns where TABLE_NAME='eip_edEmp_profile';
select * from ehrms2.ac_pwd_rule;   --	密碼原則設定檔
select * from ehrms2.ac_group;  --	成員群組檔
select * from ehrms2.ac_group_rule; --	成員群組-規則檔
select * from ehrms2.ac_group_expand;   --	成員群組-員工展開檔
select * from ehrms2.ac_role;   --	角色資料檔
select * from information_schema.columns where TABLE_NAME='ac_role';
select * from ehrms2.ac_role_right; --	角色-功能權限
select * from ehrms2.ac_role_field; --	角色-個資欄位
select * from ehrms2.ac_user;   --	使用者資料檔
select * from information_schema.columns where TABLE_NAME='ac_user';
select * from ehrms2.ac_user_role;  --	使用者 - 擁有角色
select * from ehrms2.ac_user_cmp;   --	使用者 - 可管理公司
select * from ehrms2.ac_user_role_give; --	使用者 - 角色授權
select * from ehrms2_log.sys_log_login; --   帳號登入紀錄
select * from ehrms2_log.sys_log_pwd_change;    --  帳號密碼變更紀錄

select * from information_schema.tables where TABLE_NAME='ac_group'; -- 也可以查看table的狀況
select * from information_schema.columns where TABLE_NAME='ac_user'; -- 確定一下schema結構 --

-- auto increment sample
/*
CREATE TABLE animals (
     id MEDIUMINT NOT NULL AUTO_INCREMENT,
     name CHAR(30) NOT NULL,
     PRIMARY KEY (id)
 );

INSERT INTO animals (name) VALUES
    ('dog'),('cat'),('penguin'),
    ('fox'),('whale'),('ostrich');
*/

SELECT 2 /* +1 */;
SELECT 1 /*! +1 */;
SELECT 1 /*!50101 +1 */;
SELECT 2 /*M! +1 */;
SELECT 2 /*M!50101 +1 */;

use ehrms2;
drop table animals;
create table animals (
	id MEDIUMINT NOT NULL AUTO_INCREMENT COMMENT 'id-這個是欄位說明註解',
    name CHAR(30) NOT NULL COMMENT 'name-這個是欄位名稱註解',
    primary key (ID)
);
select * from information_schema.columns where table_name = 'animals';

INSERT INTO `ehrms2`.`animals` (`id`, `name`) VALUES ('50', 'aa');
INSERT INTO `ehrms2`.`animals` (`name`) VALUES ('bb');
INSERT INTO `ehrms2`.`animals` (`name`) VALUES ('cc');
INSERT INTO `ehrms2`.`animals` (`name`) VALUES ('dd');
INSERT INTO `ehrms2`.`animals` (`name`) VALUES ('ee');
select * from animals;
UPDATE `ehrms2`.`animals` SET `name` = 'aaddd' WHERE (`id` = '50');
DELETE FROM `ehrms2`.`animals` WHERE (`id` = '50');