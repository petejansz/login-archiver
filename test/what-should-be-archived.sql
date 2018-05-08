-- what-should-be-archived.sql
select
    login_id ,
    contract_identity ,
    key_access_value ,
    login_date ,
    logout_date
from GMS4.sms_user_login
where
(   -- real people:
    login_date < ( current date - 36 months ) 
)
or
(   -- automated monitor accounts:
    login_date < ( current date - 7 days ) 
    and key_access_value in 
    (
        'calottomobileadm@gmail.com',
        'nota2ndchancewinner@gmail.com',
        'cslmobile1@gmail.com',
        'thirtyplus@calottery.com',
        'dca_ren_staff@gtech.com'
    )
)
FETCH first 10000 rows only;
commit;
