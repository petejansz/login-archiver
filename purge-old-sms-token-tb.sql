-- Purge old SMS_TOKEN_TB

delete
(
    select * from GMS4.sms_token_tb where lastupdate_date < current date - 3 months
    fetch first 1000 rows only
    with ur
);

commit;
