-- Purge old sms_reserve_contracts
-- RESERVE_STATUS_ID	NAME
--                 1	REQUESTED
--                 2	CONFIRMED

delete
(
    select * from GMS4.sms_reserve_contracts where reserve_status_id=1 and last_updated < current date - 3 months
    fetch first 1000 rows only
    with ur
);

commit;
