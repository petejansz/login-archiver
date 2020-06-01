-- Purge old SMS_reserve_key_access

delete
(
    select * from GMS4.sms_reserve_key_access where reserve_date < current date - 3 months
    fetch first 1000 rows only
    with ur
);

commit;

