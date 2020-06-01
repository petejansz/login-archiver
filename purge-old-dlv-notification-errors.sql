-- Purge old dlv_notifications driven by dlv_notification_errors
-- Delete rows from child, parent related tables.

with
    -- 1. DELETE rows from child table, storing the deleted key in temp-table DELETED_notification_errors
    DELETED_notification_errors ( ext_notification_key ) as
    (
        select ext_notification_key
        from old table 
        ( 
            delete from GMS4.dlv_notification_errors
            where ext_notification_key in
            (
                select ext_notification_key 
                from GMS4.dlv_notification_errors 
                where 
                    error_time <= current timestamp - 1 years
                fetch first 1000 rows only
            )
        )
    ),
    
    -- 2. DELETE rows from peer child table:
    DELETED_notification_req_details ( ext_notification_key ) as
    (
        select ext_notification_key
        from old table 
        ( 
            delete from GMS4.dlv_notification_req_details where ext_notification_key in ( select ext_notification_key from DELETED_notification_errors )
        )        
    ),
     
    -- 3. DELETE rows from parent table:
    DELETED_notification_requests ( ext_notification_key ) as
    (
        select ext_notification_key
        from old table 
        ( 
             delete from GMS4.dlv_notification_requests where ext_notification_key in ( select ext_notification_key from DELETED_notification_errors )
        )
    )
      
    (
        -- Satisfy login-arhciver.sh
        select concat(concat(concat('DELETE', chr(10)),  ' rows affected : '), count(*)) from DELETED_notification_requests
    )    
;

