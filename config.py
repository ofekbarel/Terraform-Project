import psycopg2

conn = psycopg2.connect(
    host= "10.0.2.10",
    database="terraform",
    user="postgres",
    password="Ofek123456789"
)