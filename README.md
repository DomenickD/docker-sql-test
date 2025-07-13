# Docker SQL Experiment


### What it does

- Uses Docker to stand up a database (postgres).
- Instatntiates the database.
- Then builds a streamlit app to interact with the database. 

## How to run:

1. `git clone https://github.com/DomenickD/docker-sql-test.git`

2. Open docker desktop 
    - (Can download here for windows)[https://docs.docker.com/desktop/setup/install/windows-install/]
    - (Can download here for Mac)[https://docs.docker.com/desktop/setup/install/mac-install/]

2. `docker build -t db_test .`

3. `docker run --name pg_db -e POSTGRES_PASSWORD=password -d db_test`

4. `pip install streamlit`

5. `streamlit run app.py`

6. View the `http://localhost:8501`