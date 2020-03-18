-- purge old GMS4.prv_recovery_actions

delete
(
    select * from GMS4.prv_recovery_actions where status_id in (1, 3, 6, 7) and creation_date < current date - 31 days
    fetch first 1000 rows only
    with ur
);

commit;

