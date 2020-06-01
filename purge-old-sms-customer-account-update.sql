-- Keep last 5 updates per user.

DELETE from
(
    SELECT customer_account_update_id 
    FROM
    ( 
       SELECT row_number() over (partition BY physical_customer_data_id ORDER BY account_update_date DESC) 
            AS cau_row_nr, customer_account_update_id
       FROM  GMS4.sms_customer_account_update
       WHERE physical_customer_data_id IN
       ( 
            SELECT physical_customer_data_id 
            FROM   GMS4.sms_customer_account_update
            WHERE  physical_customer_data_id not in (5387223, 5390759, 616064)
            GROUP BY    physical_customer_data_id
            HAVING COUNT(physical_customer_data_id) > 5
            ORDER BY    physical_customer_data_id
            fetch first 500 rows only
        )
        
        ORDER BY customer_account_update_id
    )
    
    WHERE    cau_row_nr > 5
    ORDER BY customer_account_update_id
    fetch first 1000 rows only
);
commit;
