-- Purge old SMS_TOKEN_TB
-- Purging policy based on STATUS_ID in (1,2,3) (validated, expired, invalidated) and older than 3-mos

delete
(
    select * from GMS4.sms_token_tb where status_id in (1, 2, 3) and lastupdate_date < current date - 3 months
    fetch first 1000 rows only
    with ur
);

commit;
