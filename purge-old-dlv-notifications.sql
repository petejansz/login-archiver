-- Delete rows from two related tables.

with
    -- 1. DELETE rows from child table, storing the deleted key in temp-table DELETED_notification_req_details
    DELETED_notification_req_details ( ext_notification_key ) as
    (
        select ext_notification_key
        from old table 
        ( 
            delete from GMS4.dlv_notification_req_details
            where ext_notification_key in
            (
                select ext_notification_key 
                from GMS4.dlv_notification_req_details 
                where 
                    last_updated <= current timestamp - 6 months
                    and template_name not in ( 'WinnerNotification' )
                fetch first 1000 rows only
            )
        )
    ),
    
    -- 2. DELETE rows from parent table
    DELETED_notification_requests ( ext_notification_key ) as
    (
        select ext_notification_key
        from old table ( delete from GMS4.dlv_notification_requests where ext_notification_key in ( select ext_notification_key from DELETED_notification_req_details ) )
    )
       
    (
        -- Satisfy login-arhciver.sh
        select concat(concat(concat('DELETE', chr(10)),  'rows affected : '), count(*)) from DELETED_notification_requests
    )    
;

