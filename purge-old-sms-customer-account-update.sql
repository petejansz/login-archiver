-- Purge old SMS_CUSTOMER_ACCOUNT_UPDATE

delete
(
    select * from GMS4.sms_customer_account_update where account_update_date < (current date - 31 days)
    fetch first 1000 rows only
    with ur
);

commit;

