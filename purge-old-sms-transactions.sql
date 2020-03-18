-- Purge old sms transactions

delete
(
    select * from GMS4.sms_transactions where creation_date < (current date - 31 days)
    fetch first 1000 rows only
    with ur
);

commit;

