# PgFailover
PostgreSQL failover master standby

Test case:
- DB query check through virtual ip
- DNS check
- Gateway check

Setting pg_hba.conf:
- allow trust connect to virtual ip, database and username
