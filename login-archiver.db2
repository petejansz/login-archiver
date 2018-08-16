-- Description: CAS PDDB GMS4.sms_user_login table archiver.
--              CASA-8458, CASA-11201, CASA-11202
--              Copy records from GMS4.sms_user_login to GMS4.sms_user_login_archive
--              Delete copied records from GMS4.sms_user_login
--  Author: Pete Jansz

insert into GMS4.sms_user_login_archive
    select
        login_id ,
        physical_customer_data_id ,
        contract_identity ,
        contract_type_id ,
        key_access_value ,
        key_access_type_id ,
        ext_system_id ,
        login_date ,
        logout_date ,
        ip_address ,
        provider_id ,
        login_type_id ,
        api_key,
        device_id,
        current date
    from GMS4.sms_user_login
    where
    (   -- Runscope, automated monitor accounts:
        login_date < ( current date - 7 days ) and
        key_access_value in 
        (
            'calottomobileadm@gmail.com',
            'nota2ndchancewinner@gmail.com',
            'cslmobile1@gmail.com',
            'thirtyplus@calottery.com',
            'dca_ren_staff@gtech.com'
        )
    )
    or
    (   -- real people:
        login_date < ( current date - 36 months ) 
    )
FETCH first 10000 rows only;
commit;

delete GMS4.sms_user_login
where 
    login_id in (select login_id from GMS4.sms_user_login_archive where archive_date = current date)
;
commit;

