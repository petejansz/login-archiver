-- Description: CAS PDDB GMS4.sms_user_login table archiver.
--              CASA-8458, CASA-11201, CASA-11202
--              Copy records from GMS4.sms_user_login to GMS4.sms_user_login_archive
--              Delete copied records from GMS4.sms_user_login
--  Author: Pete Jansz

-- jcaplin: the following statements are not the best way of dealing with things,
-- but it's the best we can do with the hand we have been dealt. NB: we play heavily
-- into the fact that the clustered index on SMS_USER_LOGIN is LOGIN_ID by virtue of the
-- the fact it is the first index defined on the table and no explicit clustered index 
-- exists. So we try and do the heavy lifting with "in LOGIN_ID order" as mind as much
-- as possible...
--
-- We assume login ids are approximately incremental relative to time. Therefore, we
-- expect the leftmost entries in the table to be the oldest (smallest login_id - 
-- clustered index). To cull records older than 3 years, we look at the first 500 rows in the
-- table and select those away that are older than 3 years. If there is some disordering between
-- login_id and login_date (i.e. the next login_id is higher but the actual login_date is lower)
-- then it's possible we'll have data 3 years and change old in the table... But that should 
-- fix itself when the next calendar day kicks off
--
-- Note also for whatever reason, the login_id column in _archive is not unqique. There might be
-- (are) dupes in there. We take advantage of that here. The job might finish across calendar dates
-- and so "CURRENT DATE" is no longer in context. It's ok - this thing is eventually consistent.
--
-- We do a sweep for players with > 5 login records, then for > 3 year old logins. We copy
-- 500 at most per iteration.
--
-- Then we try to delete 1000 records in the archive table that are still in the source table. 
--
--
-- RUNSCOPE USER DATA:
--
-- select value from GMS4.SMS_CUSTOMER_CONTACTS where SMS_CUSTOMER_CONTACTS.PHYSICAL_CUSTOMER_DATA_ID in
--  (5387223, 5390759) and SMS_CUSTOMER_CONTACTS.CONTACT_TYPE_ID=1
--
-- dca_ren_staff@gtech.com
-- calottomobileadm@gmail.com
--


-- {query14}: THIS DEALS WITH PLAYER WHO HAVE > 5 LOGINS.
--           Consume {query3} and insert into the archive table
insert into GMS4.sms_user_login_archive
    SELECT
        login_id,
        physical_customer_data_id,
        contract_identity,
        contract_type_id,
        key_access_value,
        key_access_type_id,
        ext_system_id,
        login_date,
        logout_date,
        ip_address,
        provider_id,
        login_type_id,
        api_key,
        device_id,
        CURRENT DATE
    FROM
        SMS_USER_LOGIN
    WHERE
        LOGIN_ID IN
        (
            -- {query13}: fetch the first 500 login_ids from {query2} where the login record number
            --           (user_login_number) > 5 and then just to be extra safe - order by login id.
            --           This is probably pointless but I'm keeping it because it makes me feel 
            --           better.
            SELECT
                LOGIN_ID
            FROM
                (
                    -- {query12}: for each of the customers that {query1} yields, fetch all their
                    --           logins _AND ORDER BY_ login_id (clustered order)
                    SELECT
                        row_number() over (partition BY physical_customer_data_id ORDER BY login_date
                        DESC) AS user_login_number,
                        login_id
                    FROM
                        sms_user_login
                    WHERE
                        physical_customer_data_id IN
                        (
                            --
                            -- {query11}: find the first 100 customers that have more than
                            --           5 login records. Order it just so if we're monitoring
                            --           we can keep an eye on the culling of a specific player's
                            --           data
                            SELECT
                                physical_customer_data_id
                            FROM
                                sms_user_login
                            WHERE
                                 physical_customer_data_id NOT IN (5387223, 5390759)
                            GROUP BY
                                physical_customer_data_id
                            HAVING
                                COUNT(physical_customer_data_id) > 5
                            ORDER BY
                                physical_customer_data_id
                            FETCH
                                FIRST 100 rows only)
                            -- {query11}
                    ORDER BY
                        login_id)
                    -- {query12}
            WHERE
                user_login_number > 5
            ORDER BY
                LOGIN_ID
            FETCH
                FIRST 500 rows only);
commit;

--
-- {query22}: consume all the login_id's from {query21} whose login_date is more than 
--            three years old, pull the record and insert into archive.
insert into GMS4.sms_user_login_archive
    SELECT
        login_id,
        physical_customer_data_id,
        contract_identity,
        contract_type_id,
        key_access_value,
        key_access_type_id,
        ext_system_id,
        login_date,
        logout_date,
        ip_address,
        provider_id,
        login_type_id,
        api_key,
        device_id,
        CURRENT DATE
    FROM
        sms_user_login
    WHERE
        login_id IN
        (
            --
            -- {query21}: see above - we assume login_id's increment approximately over time,
            --            so let's fetch the first 500 records
            SELECT
                login_id
            FROM
                sms_user_login
            ORDER BY
                login_id
            FETCH
                FIRST 500 rows only)
            -- {query21}
    AND login_date < (CURRENT DATE - 3 years);
commit;

--
-- {query32}: consumes the login_id's frmo {query31} and deletes them
DELETE
FROM
    sms_user_login
WHERE
    login_id IN
                 (
                --
                -- {query31}: _ARCHIVE is clustered on ARCHIVE_DATE. We capitalize on that
                --            by fetching all rows archived today and joining with
                --            the source table - this query returns those login_ids that exist
                --            in both the login table AND the archive table
                 SELECT DISTINCT
                     sula.login_id
                 FROM
                     sms_user_login_archive sula
                 INNER JOIN
                     sms_user_login sul
                 ON
                     sula.login_id = sul.login_id
                 WHERE
                     sula.archive_date = CURRENT DATE
                 ORDER BY
                     sula.login_id
                 FETCH
                     FIRST 1000 ROWS ONLY);
commit;

