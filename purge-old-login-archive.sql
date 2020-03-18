delete
(
    select * from GMS4.sms_user_login_archive where login_date <= (current date - 1 year)
    fetch first 1000 rows only
    with ur
);

commit;
