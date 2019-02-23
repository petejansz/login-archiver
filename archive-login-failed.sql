-- see comments in archive-login.sql

insert into GMS4.sms_user_login_failed_archive
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
        result,
        provider_id,
        login_type_id,
        api_key,
        device_id,
        CURRENT DATE
    FROM
        SMS_USER_LOGIN_FAILED
    WHERE
        LOGIN_ID IN
        (
            SELECT
                LOGIN_ID
            FROM
                (
                    SELECT
                        row_number() over (partition BY physical_customer_data_id ORDER BY login_date
                        DESC) AS user_login_number,
                        login_id
                    FROM
                        sms_user_login_failed
                    WHERE
                        physical_customer_data_id IN
                        (
                            
                            SELECT
                                physical_customer_data_id
                            FROM
                                sms_user_login_failed
                            GROUP BY
                                physical_customer_data_id
                            HAVING
                                COUNT(physical_customer_data_id) > 5
                            ORDER BY
                                physical_customer_data_id
                            FETCH
                                FIRST 100 rows only)
                    ORDER BY
                        login_id)
            WHERE
                user_login_number > 5
            ORDER BY
                LOGIN_ID
            FETCH
                FIRST 500 rows only);
commit;

insert into GMS4.sms_user_login_failed_archive
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
        result,
        provider_id,
        login_type_id,
        api_key,
        device_id,
        CURRENT DATE
    FROM
        sms_user_login_failed
    WHERE
        login_id IN
        (
            SELECT
                login_id
            FROM
                sms_user_login_failed
            ORDER BY
                login_id
            FETCH
                FIRST 500 rows only)
    AND login_date < (CURRENT DATE - 3 years);
commit;

DELETE
FROM
    sms_user_login_failed
WHERE
    login_id IN
                 (
                 SELECT DISTINCT
                     sula.login_id
                 FROM
                     sms_user_login_failed_archive sula
                 INNER JOIN
                     sms_user_login_failed sul
                 ON
                     sula.login_id = sul.login_id
                 WHERE
                     sula.archive_date = CURRENT DATE
                 ORDER BY
                     sula.login_id
                 FETCH
                     FIRST 1000 ROWS ONLY);
commit;
