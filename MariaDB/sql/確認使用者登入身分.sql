select * from ac_user;
select * from ac_user where USER_ID=217;

 select fn_sys_code_GetName('global.messageType','okonly','zh-tw','en');
 
 select * from sys_code where CODE_TYPE = 'ac.loginMethod';
 select * from AC_PWD_RULE;
 select USER_ID, PWD_RULE_ID from ac_user;
 
 select U.USER_ID, U.PWD_RULE_ID, R.LOGIN_METHOD, fn_sys_code_GetName('ac.loginMethod', R.LOGIN_METHOD,'zh-tw','en') 
 from ac_user U left join AC_PWD_RULE R on U.PWD_RULE_ID=R.PWD_RULE_ID;
 
 select  fn_sys_code_GetName('ac.loginMethod', 1,'zh-tw','en');
 
select count(*) from sys_code;
show create table sys_code;
show procedure status;
show function status;
show create function fn_sys_code_GetName;

select * from ac_user;

SET @EHRMS2_KEY = '1qaz!QAZ';
select USER_ID, USER_ACCOUNT, fn_util_Decode(USER_ACCOUNT) from ac_user;
select USER_ID, USER_ACCOUNT, fn_util_Decode(USER_ACCOUNT) from ac_user where USER_ID IN (72, 217);

update ac_user set USER_ACCOUNT = fn_util_Encode('鄧紫棋') where USER_ID=72;