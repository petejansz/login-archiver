-- Delete RUNSCOPE user logins identified by their physical_customer_data_id:
--   dca_ren_staff@gtech.com (5387223)
--   calottomobileadm@gmail.com (5390759)
--   nota2ndchancewinner@gmail.com (616064)

delete from GMS4.sms_user_login
    where
        login_id in
        (
            select login_id
            from
                (
                    select
                        row_number() over (partition by physical_customer_data_id order by login_date desc) as user_login_number, login_id
                    from GMS4.sms_user_login
                    where physical_customer_data_id in (5387223, 5390759, 616064)
                    order by login_id
                )
            where user_login_number > 1
            order by login_id
            fetch first 1000 rows only
        );
commit;
