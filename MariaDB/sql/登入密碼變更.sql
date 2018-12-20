show procedure status;
show procedure status where name = 'sp_ac_user_PwdChange';
show procedure status where name like '%Pwd%';

show create procedure sp_ac_user_CheckPwdChange;

select * from ac_user where USER_ID=217;
use ehrms2;
call sp_ac_user_CheckPwdChange(2, 'EIP', 'austinAAA', 'A105!a106', 'A105!a107', '');
#//Error Code: 1175. You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column To disable safe mode, toggle the option in Preferences -> SQL Editor and reconnect.	0.000 sec


select * from ehrms2_log.sys_log_login order by LOG_LOGIN_ID desc;

call sp_ac_user_CheckPwdChange(
CO_ID => 2								_intCO_ID : 公司ID
APP_CODE => EIP							_strAPP_CODE : 應用程式
USER_ACCOUNT => fn_util_Decode()		_strUSER_ACCOUNT : 使用者帳號
OLD_USER_PWD => 104104					_strOLD_USER_PWD : 使用者舊密碼
NEW_USER_PWD => 105105					_strNEW_USER_PWD : 使用者新密碼
										_strUSER_IP : 限制使用者IP位置
);

CREATE DEFINER=`ehrms2_user`@`%` 
PROCEDURE `sp_ac_user_CheckPwdChange`(
_intCO_ID BIGINT
, _strAPP_CODE VARCHAR(20)
, _strUSER_ACCOUNT NVARCHAR(256)
, _strOLD_USER_PWD VARCHAR(256)
, _strNEW_USER_PWD VARCHAR(256)
, _strUSER_IP VARCHAR(256))

 BEGIN
 /*
 * 功能說明 : 密碼變更
 
 * 傳入參數說明
 _intCO_ID : 公司ID
 _strAPP_CODE : 應用程式
 _strUSER_ACCOUNT : 使用者帳號
 _strOLD_USER_PWD : 使用者舊密碼
 _strNEW_USER_PWD : 使用者新密碼
 _strUSER_IP : 限制使用者IP位置
 
 * 傳回值
 recordset : 資料集
 strRETURN_CODE : '11', '密碼變更成功'
 strRETURN_CODE : '19', 'AD認證'
 strRETURN_CODE : '21', '密碼輸入錯誤'
 strRETURN_CODE : '22', '帳號被鎖定'
 strRETURN_CODE : '23', '帳號已關閉'
 strRETURN_CODE : '24', '帳號未認證'
 strRETURN_CODE : '25', '帳號IP錯誤'
 strRETURN_CODE : '31', '應用程式不存在'
 strRETURN_CODE : '32', '該使用者帳號不存在'
 strRETURN_CODE : '33', '帳號狀態錯誤'
 strRETURN_CODE : '34', '認證模式錯誤'
 strRETURN_CODE : '41', '密碼最小長度檢查錯誤'
 strRETURN_CODE : '42', '文數字檢查'
 strRETURN_CODE : '43', '密碼需有特殊符號檢查錯誤'
 strRETURN_CODE : '44', '時間未到'
 strRETURN_CODE : '45', '與上次密碼重複'
 
 * 執行範例
 不傳公司
 call sp_ac_user_CheckPwdChange(0, 'EHRMS', '001', 'pwdold', 'pwdnew', '127.0.0.1');
 call sp_ac_user_CheckPwdChange(1, 'EHRMS', '001', 'pwdold', 'pwdnew', '127.0.0.1');
 
 * 修改歷程
 2018/07/02	Andy Chao		Create  
 2018/07/17  Debby chang     修改鎖住原則
 2018/8/14   Adam.wang		新舊密碼不可以一樣
 */
 DECLARE strRETURN_CODE VARCHAR(2) DEFAULT '';
     DECLARE strRETURN_MSG VARCHAR(256) DEFAULT '';
     
     DECLARE intUSER_ID BIGINT DEFAULT 0;
     DECLARE strUSER_PWD VARCHAR(256) DEFAULT '';
     DECLARE strACCOUNT_STATUS VARCHAR(1) DEFAULT '';
     DECLARE dtPWD_CHANGE_TIME DATETIME DEFAULT '00000000';
     DECLARE dtACCOUNT_LOCKOUT_TIME DATETIME DEFAULT '00000000';
     DECLARE strUSER_IP VARCHAR(50) DEFAULT '';
     DECLARE strLOGIN_METHOD VARCHAR(1) DEFAULT '';
     DECLARE strRULE7_CHECK VARCHAR(1) DEFAULT '';
 	DECLARE intRULE7_DATA1 TINYINT DEFAULT 0;
     DECLARE strRULE7_DATA2 VARCHAR(6) DEFAULT '';
     DECLARE intRULE7_DATA3 TINYINT DEFAULT 0;
     DECLARE intRULE7_DATA4 TINYINT DEFAULT 0;
     DECLARE strRULE7_DATA5 VARCHAR(6) DEFAULT '';
     DECLARE strRULE1_CHECK VARCHAR(1) DEFAULT '';
 	DECLARE intRULE1_DATA1 TINYINT DEFAULT 0;
     DECLARE strRULE2_CHECK VARCHAR(1) DEFAULT '';
     DECLARE strRULE3_CHECK VARCHAR(1) DEFAULT '';
     DECLARE strRULE5_CHECK VARCHAR(1) DEFAULT '';
 	DECLARE intRULE5_DATA1 TINYINT DEFAULT 0;
     DECLARE strRULE6_CHECK VARCHAR(1) DEFAULT '';
 	DECLARE intRULE6_DATA1 TINYINT DEFAULT 0;
     
     DECLARE strCheckIP VARCHAR(50) DEFAULT '';
 	DECLARE intIPStar TINYINT DEFAULT 0;
     DECLARE strAction VARCHAR(1) DEFAULT '';	## '1' 解鎖, '2' 鎖定
 
 	DECLARE strLOG_STATUS VARCHAR(6) DEFAULT '';
     DECLARE intLOG_COUNT TINYINT DEFAULT 1;
     DECLARE dtFAIL_LOGIN_TIME DATETIME DEFAULT '00000000';
     DECLARE dtCHANGE_TIME DATETIME DEFAULT '00000000';
     DECLARE strNEW_PWD VARCHAR(100) DEFAULT '';
     DECLARE intCHANGE_TIME_CHECK TINYINT DEFAULT 0;
     DECLARE intCHECK_COUNT TINYINT DEFAULT 0;
 
 	## 定義 cursor 變數
 	DECLARE flag INT DEFAULT 0;
 
 	/*DECLARE tCursor CURSOR FOR
 	SELECT LOG_STATUS FROM ehrms2_log.sys_log_login WHERE LOG_USER_ID = intUSER_ID 
        AND APP_CODE = _strAPP_CODE ORDER BY LOG_DATETIME DESC;*/
        
 	DECLARE tCursor CURSOR FOR
 		 Select LOG_STATUS,LOG_DATETIME FROM ehrms2_log.sys_log_login 
 		  where LOG_DATETIME>(SELECT MAX(LOG_DATETIME) FROM ehrms2_log.sys_log_login WHERE  LOG_USER_ID = intUSER_ID  AND LOG_STATUS ='info11')
 			AND  LOG_USER_ID = intUSER_ID  AND LOG_STATUS='err21' 
 	   order by LOG_DATETIME  DESC;    
 
 
 	DECLARE tCursor2 CURSOR FOR
     SELECT CHANGE_TIME, NEW_PWD FROM ehrms2_log.sys_log_pwd_change WHERE USER_ID = intUSER_ID AND IS_CHANGE_SUCCESS = '1' ORDER BY CHANGE_TIME DESC;
 
 	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag = 1;        
     
 	CheckBlock: BEGIN
 		SET strRETURN_CODE = '11';
     
 		## 檢查應用程式是否存在
 		IF UCASE(_strAPP_CODE) <> 'EHRMS' AND UCASE(_strAPP_CODE) <> 'EIP' THEN
 			SET strRETURN_CODE = '31';
 			LEAVE CheckBlock;
 		END IF;
         
 		## 檢查新舊密碼不可以一樣
 		IF (_strOLD_USER_PWD=_strNEW_USER_PWD) THEN
 			SET strRETURN_CODE = '46';
 			LEAVE CheckBlock;
 		END IF;
 
 		## 檢查帳號是否存在
 		## EHRMS
 		IF UCASE(_strAPP_CODE) = 'EHRMS' THEN
 			SELECT
 				  a.USER_ID
 				, a.USER_PWD
 				, a.ACCOUNT_STATUS
 				, a.PWD_CHANGE_TIME
 				, a.ACCOUNT_LOCKOUT_TIME
 				, a.USER_IP
 				, ifnull(LOGIN_METHOD, '')
 				, ifnull(b.RULE7_CHECK, '')
 				, ifnull(b.RULE7_DATA1, 0)
 				, ifnull(b.RULE7_DATA2, '')
 				, ifnull(b.RULE7_DATA3, 0)
 				, ifnull(b.RULE7_DATA4, 0)
                 , ifnull(b.RULE7_DATA5, '')
 				, ifnull(b.RULE1_CHECK, '')
 				, ifnull(b.RULE1_DATA1, 0)
 				, ifnull(b.RULE2_CHECK, '')
 				, ifnull(b.RULE3_CHECK, '')
 				, ifnull(b.RULE5_CHECK, '')
 				, ifnull(b.RULE5_DATA1, 0)
 				, ifnull(b.RULE6_CHECK, '')
 				, ifnull(b.RULE6_DATA1, 0)
 			INTO 
 				  intUSER_ID
 				, strUSER_PWD
 				, strACCOUNT_STATUS
 				, dtPWD_CHANGE_TIME
 				, dtACCOUNT_LOCKOUT_TIME
 				, strUSER_IP
 				, strLOGIN_METHOD
 				, strRULE7_CHECK
 				, intRULE7_DATA1
 				, strRULE7_DATA2
 				, intRULE7_DATA3
                 , intRULE7_DATA4
                 , strRULE7_DATA5
 				, strRULE1_CHECK
 				, intRULE1_DATA1
 				, strRULE2_CHECK
 				, strRULE3_CHECK
 				, strRULE5_CHECK
 				, intRULE5_DATA1
 				, strRULE6_CHECK
 				, intRULE6_DATA1
 			FROM ac_user AS a
 				LEFT JOIN ac_pwd_rule AS b ON a.PWD_RULE_ID = b.PWD_RULE_ID
 			WHERE a.USER_ACCOUNT = fn_util_Encode(_strUSER_ACCOUNT)
 				AND a.APP_CODE = UCASE(_strAPP_CODE);
 		## EIP
 		ELSE
 			SELECT
 				  a.USER_ID
 				, a.USER_PWD
 				, a.ACCOUNT_STATUS
 				, a.PWD_CHANGE_TIME
 				, a.ACCOUNT_LOCKOUT_TIME
 				, a.USER_IP
 				, ifnull(LOGIN_METHOD, '')
 				, ifnull(b.RULE7_CHECK, '')
 				, ifnull(b.RULE7_DATA1, 0)
 				, ifnull(b.RULE7_DATA2, '')
 				, ifnull(b.RULE7_DATA3, 0)
                 , ifnull(b.RULE7_DATA4, 0)
 				, ifnull(b.RULE7_DATA5, '')
 				, ifnull(b.RULE1_CHECK, '')
 				, ifnull(b.RULE1_DATA1, 0)
 				, ifnull(b.RULE2_CHECK, '')
 				, ifnull(b.RULE3_CHECK, '')
 				, ifnull(b.RULE5_CHECK, '')
 				, ifnull(b.RULE5_DATA1, 0)
 				, ifnull(b.RULE6_CHECK, '')
 				, ifnull(b.RULE6_DATA1, 0)
 			INTO 
 				  intUSER_ID
 				, strUSER_PWD
 				, strACCOUNT_STATUS
 				, dtPWD_CHANGE_TIME
 				, dtACCOUNT_LOCKOUT_TIME
 				, strUSER_IP
 				, strLOGIN_METHOD
 				, strRULE7_CHECK
 				, intRULE7_DATA1
 				, strRULE7_DATA2
 				, intRULE7_DATA3
                 , intRULE7_DATA4
                 , strRULE7_DATA5
 				, strRULE1_CHECK
 				, intRULE1_DATA1
 				, strRULE2_CHECK
 				, strRULE3_CHECK
 				, strRULE5_CHECK
 				, intRULE5_DATA1
 				, strRULE6_CHECK
 				, intRULE6_DATA1
 			FROM ac_user AS a
 				LEFT JOIN ac_pwd_rule AS b ON a.PWD_RULE_ID = b.PWD_RULE_ID
 			WHERE a.USER_ACCOUNT = fn_util_Encode(_strUSER_ACCOUNT)
 				AND a.APP_CODE = UCASE(_strAPP_CODE)
 				AND a.CO_ID = _intCO_ID;
 		END IF;
 			
 		IF intUSER_ID = 0 THEN
 			SET strRETURN_CODE = '32';
 			LEAVE CheckBlock;
 		END IF;
         
         ## 檢查帳號狀態不是以下狀態 1:未認證 2:鎖定 3:開啟 4:關閉
         IF strACCOUNT_STATUS NOT IN ('1', '2', '3', '4') THEN
 			SET strRETURN_CODE = '33';
 			LEAVE CheckBlock;
         END IF;
         
 		## 檢查帳號是否被鎖定
 		IF strACCOUNT_STATUS = '2' THEN
 			IF strRULE7_CHECK = '1' THEN
 				IF UCASE(strRULE7_DATA5) = 'MINUTE' THEN
 					IF NOW() >= DATE_ADD(dtACCOUNT_LOCKOUT_TIME, INTERVAL intRULE7_DATA4 MINUTE) THEN
 						SET strAction = '1';
                         ## 更新狀態為開啟
                         UPDATE ac_user SET ACCOUNT_STATUS = '3' WHERE USER_ID = intUSER_ID; 
 					ELSE
 						SET strRETURN_CODE = '22';
 						LEAVE CheckBlock;
 					END IF;
 				ELSEIF UCASE(strRULE7_DATA5) = 'HOUR' THEN
 					IF NOW() >= DATE_ADD(dtACCOUNT_LOCKOUT_TIME, INTERVAL intRULE7_DATA4 HOUR) THEN
 						SET strAction = '1';
                         ## 更新狀態為開啟
                         UPDATE ac_user SET ACCOUNT_STATUS = '3' WHERE USER_ID = intUSER_ID; 
 					ELSE
 						SET strRETURN_CODE = '22';
 						LEAVE CheckBlock;
 					END IF;
 				ELSE
 					SET strRETURN_CODE = '22';
 					LEAVE CheckBlock;
 				END IF;
 			ELSE
 				SET strRETURN_CODE = '22';
 				LEAVE CheckBlock;
 			END IF;
 		END IF;
         
 		## 檢查帳號是否被關閉
 		IF strACCOUNT_STATUS = '4' THEN
 			SET strRETURN_CODE = '23';
 			LEAVE CheckBlock;
 		END IF;
         
 		## 檢查帳號是否未認證
  		IF strACCOUNT_STATUS = '1' THEN
 			SET strRETURN_CODE = '24';
 			LEAVE CheckBlock;
         END IF;
         
         ## 帳號開啟 OR 帳號鎖定開啟狀態
  		IF strACCOUNT_STATUS = '3' OR strAction = '1' THEN
 			## 檢查 IP
             IF strUSER_IP <> '' THEN
 				## 找出第一個星號前面的IP字串
 				SET intIPStar = 1;
 				SET strCheckIP = REPLACE(SUBSTRING(SUBSTRING_INDEX(strUSER_IP, '*', intIPStar), CHAR_LENGTH(SUBSTRING_INDEX(strUSER_IP, '*', intIPStar - 1)) + 1), '*', '');
             
 				## 判斷星號之前的IP是否相符
 				IF LEFT(_strUSER_IP, LENGTH(strCheckIP)) <> strCheckIP THEN
 					SET strRETURN_CODE = '25';
 					LEAVE CheckBlock;
                 END IF;
 			END IF;		
 
 			## 帳號密碼驗證模式
 			## 帳號密碼驗證
             IF strLOGIN_METHOD = '1' THEN
 				## 密碼比對成功
 				IF password(_strOLD_USER_PWD) = strUSER_PWD THEN
 					## 檢查新密碼複雜性
                     ## 最小長度
                     IF strRULE1_CHECK = '1' THEN
 						IF LENGTH(_strNEW_USER_PWD) < intRULE1_DATA1 THEN
 							SET strRETURN_CODE = '41';
 							LEAVE CheckBlock;
                         END IF;
                     END IF;
                     ## 文數字檢查
                     IF strRULE2_CHECK = '1' THEN
 						IF (_strNEW_USER_PWD REGEXP '(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])') = false THEN
 							SET strRETURN_CODE = '42';
 							LEAVE CheckBlock;
 						END IF;
                     END IF;
                     ## 密碼需有特殊符號檢查
                     IF strRULE3_CHECK = '1' THEN
 						IF (_strNEW_USER_PWD REGEXP '[^_a-zA-Z0-9]') = false THEN
 							SET strRETURN_CODE = '43';
 							LEAVE CheckBlock;
 						END IF;
                     END IF;
                     ## 重複密碼次數 && 不得變更時間檢查
                     IF strRULE5_CHECK = '1' OR strRULE6_CHECK = '1' THEN
 						OPEN tCursor2;			
 						myLOOP: LOOP
 							FETCH tCursor2 INTO dtCHANGE_TIME, strNEW_PWD;
 							
 							## 無資料則離開Loop
 							if flag = 1 THEN
 								LEAVE myLOOP;		   
 							END IF;
 
 							SET intCHECK_COUNT = intCHECK_COUNT + 1;
                             
                                     
 							## 不得變更時間檢查，只檢查第一筆資料
 							IF strRULE6_CHECK = '1' AND intCHANGE_TIME_CHECK = 0 THEN
 								SET intCHANGE_TIME_CHECK = 1;
 
 								IF NOW() < DATE_ADD(dtCHANGE_TIME, INTERVAL intRULE6_DATA1 HOUR) THEN
 									SET strRETURN_CODE = '44';
 									LEAVE CheckBlock;
 								END IF;
 							END IF;
 
 					
                                                 
 							## 重複密碼次數
                             IF strRULE5_CHECK = '1' THEN
                                 ##adam.wang(2018/8/14)改成>,不然重覆前1次的會跳掉
                                 iF intCHECK_COUNT > intRULE5_DATA1 THEN
 								##IF intCHECK_COUNT >= intRULE5_DATA1 THEN
 									LEAVE myLOOP;
 								END IF;
 
 	
 								IF (password(_strNEW_USER_PWD) = strNEW_PWD) THEN
 									SET strRETURN_CODE = '45';
 									LEAVE CheckBlock;
                                 END IF;
                             END IF;
 
                             IF strRULE5_CHECK <> '1' AND intCHANGE_TIME_CHECK = 1 THEN
 								LEAVE myLOOP;
 							END IF;
 
 						END LOOP myLOOP;
 
 						CLOSE tCursor2;
 
 						SET flag = 0;   
 					END IF;
 				## 密碼比對失敗
                 ELSE
 					SET strRETURN_CODE = '21';
 
 					OPEN tCursor;			
 					myLOOP: LOOP
 						FETCH tCursor INTO strLOG_STATUS,dtFAIL_LOGIN_TIME;
 						
 						## 無資料則離開Loop
 						if flag = 1 THEN
 							LEAVE myLOOP;		   
 						END IF;
                         
                         IF strRULE7_CHECK='1' and  UCASE(strLOG_STATUS) = 'ERR21'  THEN
 							IF UCASE(strRULE7_DATA2) = 'MINUTE' THEN
 								IF  DATE_ADD(dtFAIL_LOGIN_TIME, INTERVAL intRULE7_DATA1 MINUTE)>=NOW() THEN
                                 	SET intLOG_COUNT = intLOG_COUNT + 1;
 								END IF;
 							ELSEIF UCASE(strRULE7_DATA2) = 'HOUR' THEN
 								IF   DATE_ADD(dtFAIL_LOGIN_TIME, INTERVAL intRULE7_DATA1 HOUR)>=NOW() THEN
 										SET intLOG_COUNT = intLOG_COUNT + 1;
 								END IF;
 						END IF;
                         ## 登入失敗的 LOG
 
                             ## 連續錯誤累積次數已達鎖定次數
                             IF intLOG_COUNT = intRULE7_DATA3 THEN
 								## 更新狀態為鎖定
 								UPDATE ac_user SET ACCOUNT_STATUS = '2', ACCOUNT_LOCKOUT_TIME = now() WHERE USER_ID = intUSER_ID; 
 								LEAVE myLOOP;
                             END IF;
 						## 不是登入失敗的LOG，離開LOOP
 						ELSE
 							LEAVE myLOOP;
                         END IF;
 					END LOOP myLOOP;
 
 					CLOSE tCursor;
 
 					SET flag = 0;   
 
                     #######################
                 END IF;
 			## AD認證
             ELSEIF strLOGIN_METHOD = '2' THEN
 				SET strRETURN_CODE = '19';
 				LEAVE CheckBlock;
             ELSE
 				SET strRETURN_CODE = '34';
 				LEAVE CheckBlock;
             END IF;
 		END IF;
 	END CheckBlock;
 	
     ## 更新密碼
     IF strRETURN_CODE = '11' THEN
 		IF UCASE(_strAPP_CODE) = 'EHRMS' THEN
 			UPDATE ac_user SET
 				  USER_PWD = password(_strNEW_USER_PWD)
 				, PWD_CHANGE_TIME = now()
                 , E_DATETIME = now()
 			WHERE USER_ACCOUNT = fn_util_Encode(_strUSER_ACCOUNT)
 				AND APP_CODE = UCASE(_strAPP_CODE);
 		ELSE
 			UPDATE ac_user SET
 				  USER_PWD = password(_strNEW_USER_PWD)
 				, PWD_CHANGE_TIME = now()
                 , E_USER_ID=intUSER_ID
                 , E_DATETIME = now()
 			WHERE USER_ACCOUNT = fn_util_Encode(_strUSER_ACCOUNT)
 				AND APP_CODE = UCASE(_strAPP_CODE)
 				AND CO_ID = _intCO_ID;
         END IF;
 	END IF;
 
     ## 密碼輸入錯誤需寫入登入 Log
     IF strRETURN_CODE = '21' THEN
 		INSERT INTO ehrms2_log.sys_log_login
         (
 			  LOG_IP
 			, APP_CODE
 			, LOG_USER_ID
 			, LOG_ACCOUNT
 			, LOG_DATETIME
 			, LOG_EVENT_TYPE
 			, LOG_STATUS
 		) VALUES (
 			  _strUSER_IP
 			, _strAPP_CODE
 			, intUSER_ID
 			, _strUSER_ACCOUNT
 			, now()
 			, 'err'
 			, CONCAT('err', strRETURN_CODE)
         );
     END IF;
     
     ## 寫入sys_log_pwd_change
     IF intUSER_ID > 0 THEN
 		INSERT INTO ehrms2_log.sys_log_pwd_change
         (
 			  EXEC_IP
 			, USER_ID
 			, CHANGE_TIME
 			, OLD_PWD
 			, NEW_PWD
 			, IS_CHANGE_SUCCESS
 			, C_DATETIME
 			, E_DATETIME
 		) VALUES (
 			  _strUSER_IP
 			, intUSER_ID
 			, now()
 			, password(_strOLD_USER_PWD)
 			, password(_strNEW_USER_PWD)
 			, CASE WHEN strRETURN_CODE = '11' THEN '1' ELSE '0' END
 			, now()
 			, now()
         );
     END IF;
     
     ## 訊息
 	IF strRETURN_CODE = '11' THEN
 		SET strRETURN_MSG = '密碼變更成功';
 	ELSEIF strRETURN_CODE = '19' THEN
 		SET strRETURN_MSG = 'AD認證';
 	ELSEIF strRETURN_CODE = '21' THEN
 		SET strRETURN_MSG = '密碼輸入錯誤';
 	ELSEIF strRETURN_CODE = '22' THEN
 		SET strRETURN_MSG = '帳號被鎖定';
 	ELSEIF strRETURN_CODE = '23' THEN
 		SET strRETURN_MSG = '帳號已關閉';
 	ELSEIF strRETURN_CODE = '24' THEN
 		SET strRETURN_MSG = '帳號未認證';
 	ELSEIF strRETURN_CODE = '25' THEN
 		SET strRETURN_MSG = '帳號IP錯誤';
 	ELSEIF strRETURN_CODE = '31' THEN
 		SET strRETURN_MSG = '應用程式不存在';
 	ELSEIF strRETURN_CODE = '32' THEN
 		SET strRETURN_MSG = '帳號不存在';
 	ELSEIF strRETURN_CODE = '33' THEN
 		SET strRETURN_MSG = '帳號狀態錯誤';
 	ELSEIF strRETURN_CODE = '34' THEN
 		SET strRETURN_MSG = '認證模式錯誤';
 	ELSEIF strRETURN_CODE = '41' THEN
 		SET strRETURN_MSG = '密碼最小長度檢查錯誤';
  	ELSEIF strRETURN_CODE = '42' THEN
 		SET strRETURN_MSG = '文數字檢查錯誤';
  	ELSEIF strRETURN_CODE = '43' THEN
 		SET strRETURN_MSG = '密碼需有特殊符號檢查錯誤';
  	ELSEIF strRETURN_CODE = '44' THEN
 		SET strRETURN_MSG = '時間未到';
  	ELSEIF strRETURN_CODE = '45' THEN
 		SET strRETURN_MSG = '與上次密碼重複';
  	ELSEIF strRETURN_CODE = '46' THEN
 		SET strRETURN_MSG = '新舊密碼不可以一樣';
 	END IF;
 
 	## 回傳結果
 	SELECT strRETURN_CODE AS RETURN_CODE, strRETURN_MSG AS RETURN_MSG, intUSER_ID as USER_ID;
 END