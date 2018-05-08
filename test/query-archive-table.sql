select 
    login_id,
    contract_identity,
    login_date,
    key_access_value

from GMS4.sms_user_login_archive 
--where archive_date = current date
;
