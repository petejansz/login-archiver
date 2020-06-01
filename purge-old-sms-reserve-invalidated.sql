-- Purge old SMS_RESERVE_INVALIDATED

delete
(
    select * from GMS4.sms_reserve_invalidated where last_updated < current date - 3 months
    fetch first 1000 rows only
    with ur
);

commit;

