# 建立mariadb
- 建立起動語法
- 找到mount dir path `/var/lib/mysql`
- 密碼存在在dir path當中，如果已經有mount mysql 相關volumn，密碼需要自行設定。
- 在第一次倒入DB的時候需要建立一下資料庫`ehrms2`
```sql
#--建立DB的語法
CREATE DATABASE ehrms2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
#--刪除DB重新建立
drop database ehrms2;
#--查看一下TABLE建立的狀況
use ehrms2;
show tables from ehrms2;
```
倒入資料庫
```sql
mysql -u root -p ehrms2<DB_104crm_2018_12_10_23_00.sql
```