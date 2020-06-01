-- Purge old dlv_notifications driven by dlv_notification_req_details
-- Delete rows from child, parent related tables.

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
                    last_updated <= current timestamp - 9 months
                    and template_name not in ( 'WinnerNotification' )
                    and ext_notification_key not in 
                    (
                        select ext_notification_key from GMS4.dlv_notification_errors
                    )
                fetch first 1000 rows only
            )
        )
    ),
    
    -- 2. DELETE rows from peer child table:
    DELETED_dlv_notification_errors ( ext_notification_key ) as
    (
        select ext_notification_key
        from old table 
        ( 
            delete from GMS4.dlv_notification_errors where ext_notification_key in ( select ext_notification_key from DELETED_notification_req_details )
        )        
    ),
     
    -- 3. DELETE rows from parent table
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

