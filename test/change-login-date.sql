update sms_user_login
set login_date = CURRENT DATE - 1100 days --, key_access_value = 'calottomobileadm@gmail.com'
where 
--    KEY_ACCESS_VALUE = 'test50@yopmail.com'
    
   LOGIN_ID IN (1784,1785,1786,1787,1788,1789,1790,1791,1792,1793)
    
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