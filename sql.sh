docker build -t assignmnet3 .
docker run --name pg_db -e POSTGRES_PASSWORD=password -d assignmnet3
docker exec -it pg_db /bin/bash
psql -U postgres
