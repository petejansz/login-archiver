-- Purge old sms_reserve_contracts

delete
(
    select * from GMS4.sms_reserve_contracts where reserve_status_id=2 and last_updated < current date - 3 months
    fetch first 1000 rows only
    with ur
);

commit;
