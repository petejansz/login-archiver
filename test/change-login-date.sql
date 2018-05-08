update sms_user_login
set login_date = CURRENT DATE - 40 months 
where 
    KEY_ACCESS_VALUE like 'test%'
--    KEY_ACCESS_VALUE NOT in
--    (
--        'calottomobileadm@gmail.com',
--        'nota2ndchancewinner@gmail.com',
--        'cslmobile1@gmail.com',
--        'thirtyplus@calottery.com',
--        'dca_ren_staff@gtech.com', 'test3@yopmail.com', 'test32@yopmail.com', 'test33@yopmail.com'
--    ) 
;
commit;