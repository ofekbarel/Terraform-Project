from flask import Flask, render_template
from config import conn

app = Flask(__name__)
cursor = conn.cursor()


query = '''
CREATE TABLE IF NOT EXISTS cars (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);
'''

query2 = '''
insert into cars (name)
values ('Toyota'),
('BMW'),
('Skoda');
'''

cursor.execute(query)
conn.commit()
cursor.execute(query2)
conn.commit()



@app.route('/')
def index():
    cursor2 = conn.cursor()
    cursor2.execute('SELECT * FROM cars')
    results = cursor2.fetchall()

    return render_template("index.html", results=results)

if __name__ == "__main__":
    app.run(debug=True)


