show procedure status where name like '%pwd%';
use ehrms2;
show create procedure sp_ac_user_CheckPwdChange;

select *, PWD_RULE_ID from ac_user where USER_ID = 217;
select * from ac_pwd_rule where PWD_RULE_ID = 175;
select * from information_schema.columns where TABLE_NAME ="ac_pwd_rule";
select COLUMN_NAME, COLUMN_COMMENT from information_schema.columns where TABLE_NAME ="ac_pwd_rule";
select COLUMN_NAME, COLUMN_COMMENT from information_schema.columns where TABLE_NAME ="ac_user";

call sp_ac_user_PwdPaidChange(1, 2, 3, 4, 5, 6);
select password('abcd');

## 確定一下相同的pwd log 需要透過 TYPE_FLAG 區分是哪一類的密碼登入錯誤訊息
select * from ehrms2_log.sys_log_login;
select * from ehrms2_log.sys_log_pwd_change;