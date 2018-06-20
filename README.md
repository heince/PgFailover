# PgFailover
PostgreSQL failover primary to secondary

Initial Configuration:
- etc/node.conf     (set node role)
- etc/db.conf       (set db config)
- etc/network.conf  (set vip, dns ip, gateway) 

Setting pg_hba.conf:
- allow trust connect to virtual ip, database and username

Custom shell script:
- bin/promote.sh    (promote secondary to primary)
- bin/start_vip.sh  (start virtual ip)
- bin/stop_vip.sh   (stop virtual ip)
- bin/stop_db.sh    (stop database)

Test case:
- DB query check through virtual ip
- DNS check
- Gateway check

