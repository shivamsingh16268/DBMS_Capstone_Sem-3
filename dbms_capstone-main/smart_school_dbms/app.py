import os
from flask import Flask, jsonify, request, send_file
import mysql.connector

app = Flask(__name__)
BASE = os.path.dirname(os.path.abspath(__file__))

DB = dict(
    host="localhost",
    user="root",
    password=os.environ.get("DB_PASSWORD", "your_password"),
    database="smart_school",
)


def query(sql, args=()):
    con = mysql.connector.connect(**DB)
    cur = con.cursor(dictionary=True)
    try:
        cur.execute(sql, args)
        return cur.fetchall()
    finally:
        con.close()


def run(sql=None, args=(), proc=None):
    con = mysql.connector.connect(**DB)
    cur = con.cursor()
    try:
        if proc:
            cur.callproc(proc, args)
        else:
            cur.execute(sql, args)
        con.commit()
    finally:
        con.close()


@app.errorhandler(mysql.connector.Error)
def db_error(e):
    return jsonify(error=getattr(e, "msg", None) or str(e)), 400


@app.errorhandler(ValueError)
def value_error(e):
    return jsonify(error="Invalid input provided."), 400


@app.route("/")
def home_page():
    return send_file(os.path.join(BASE, "index.html"))


@app.route("/api/meta")
def meta():
    return jsonify(
        classes=query("SELECT class_id, class_name FROM classes ORDER BY class_id"),
        subjects=query("SELECT subject_id, subject_name FROM subjects ORDER BY subject_id"),
        students=query("SELECT student_id, name, class_id FROM students ORDER BY student_id"),
        teachers=query("SELECT teacher_id, name, monthly_salary FROM teachers ORDER BY teacher_id"),
    )


@app.route("/api/home")
def home():
    stats = query("""
        SELECT
          (SELECT COUNT(*) FROM students) AS students,
          (SELECT COUNT(*) FROM teachers) AS teachers,
          (SELECT COUNT(*) FROM classes) AS classes,
          (SELECT IFNULL(SUM(amount), 0) FROM fees) AS fees_collected
    """)[0]
    top = query("""
        SELECT name, class_name, total,
               RANK() OVER (ORDER BY total DESC) AS rank_no
        FROM v_student_total
        ORDER BY total DESC, student_id ASC
        LIMIT 3
    """)
    return jsonify(stats=stats, top=top)


# ---------- STUDENTS (class filter + name search + add + delete) ----------
@app.route("/api/students")
def students():
    class_id = request.args.get("class_id", "").strip()
    search = request.args.get("q", "").strip()
    sql = "SELECT * FROM v_student_details WHERE 1=1"
    args = []
    if class_id:
        sql += " AND class_id = %s"
        args.append(int(class_id))
    if search:
        sql += " AND name LIKE %s"
        args.append(f"%{search}%")
    sql += " ORDER BY student_id"
    return jsonify(query(sql, tuple(args)))


@app.route("/api/students", methods=["POST"])
def add_student():
    d = request.get_json() or {}
    name = (d.get("name") or "").strip()
    if not name:
        return jsonify(error="Student name is required."), 400
    run(proc="add_student", args=(name, int(d["class_id"]), (d.get("phone") or "").strip()))
    return jsonify(ok=True)


@app.route("/api/students/<int:sid>", methods=["DELETE"])
def delete_student(sid):
    run("DELETE FROM students WHERE student_id=%s", (sid,))
    return jsonify(ok=True)


# ---------- TEACHERS & SALARY (subject filter + add teacher + salary status & pay) ----------
@app.route("/api/teachers")
def teachers():
    subject_id = request.args.get("subject_id", "").strip()
    search = request.args.get("q", "").strip()
    sql = "SELECT * FROM v_teacher_salary_status WHERE 1=1"
    args = []
    if subject_id:
        sql += " AND subject_id = %s"
        args.append(int(subject_id))
    if search:
        sql += " AND name LIKE %s"
        args.append(f"%{search}%")
    sql += " ORDER BY teacher_id"
    return jsonify(query(sql, tuple(args)))


@app.route("/api/teachers", methods=["POST"])
def add_teacher():
    d = request.get_json() or {}
    name = (d.get("name") or "").strip()
    if not name:
        return jsonify(error="Teacher name is required."), 400
    salary_val = float(d.get("monthly_salary") or 45000)
    run(
        proc="add_teacher",
        args=(
            name,
            int(d["subject_id"]),
            (d.get("assigned_class") or "").strip(),
            (d.get("phone") or "").strip(),
            salary_val,
        ),
    )
    return jsonify(ok=True)


@app.route("/api/salaries", methods=["POST"])
def pay_salary():
    d = request.get_json() or {}
    run(proc="pay_salary", args=(int(d["teacher_id"]), float(d["amount"])))
    return jsonify(ok=True)


# ---------- MARKS (class filter + subject filter + min average filter + save + cursor results) ----------
@app.route("/api/marks")
def marks():
    class_id = request.args.get("class_id", "").strip()
    subject_id = request.args.get("subject_id", "").strip()
    min_avg = request.args.get("min_avg", "").strip()

    sql = """
        SELECT
          s.student_id,
          s.name,
          c.class_id,
          c.class_name,
          sub.subject_id,
          sub.subject_name,
          m.score
        FROM marks m
        JOIN students s ON s.student_id = m.student_id
        JOIN classes c ON c.class_id = s.class_id
        JOIN subjects sub ON sub.subject_id = m.subject_id
        WHERE 1=1
    """
    args = []
    if class_id:
        sql += " AND s.class_id = %s"
        args.append(int(class_id))
    if subject_id:
        sql += " AND m.subject_id = %s"
        args.append(int(subject_id))

    rows = query(sql + " ORDER BY s.student_id, sub.subject_id", tuple(args))

    grouped = {}
    for r in rows:
        sid = r["student_id"]
        if sid not in grouped:
            grouped[sid] = {
                "student_id": sid,
                "name": r["name"],
                "class_name": r["class_name"],
                "scores": {},
            }
        grouped[sid]["scores"][r["subject_name"]] = float(r["score"])

    res_map = {r["student_id"]: r["result"] for r in query("SELECT student_id, result FROM results")}
    threshold = float(min_avg) if min_avg != "" else None

    out_rows = []
    for sid, item in grouped.items():
        vals = list(item["scores"].values())
        total_val = round(sum(vals), 2)
        avg_val = round(sum(vals) / len(vals), 2) if vals else 0.0
        if threshold is not None and avg_val < threshold:
            continue
        out_rows.append({
            "student_id": sid,
            "name": item["name"],
            "class_name": item["class_name"],
            "scores": item["scores"],
            "total": int(total_val) if total_val.is_integer() else total_val,
            "avg_score": avg_val,
            "result": res_map.get(sid, "—"),
        })

    return jsonify(rows=out_rows)


@app.route("/api/marks", methods=["POST"])
def add_marks():
    d = request.get_json() or {}
    run(
        """INSERT INTO marks(student_id, subject_id, score) VALUES (%s, %s, %s)
           ON DUPLICATE KEY UPDATE score = VALUES(score)""",
        (int(d["student_id"]), int(d["subject_id"]), int(d["score"])),
    )
    return jsonify(ok=True)


@app.route("/api/marks/results", methods=["POST"])
def make_results():
    run(proc="generate_results")
    return jsonify(ok=True)


# ---------- ATTENDANCE (view + search by name; no marking option) ----------
@app.route("/api/attendance")
def attendance():
    search = request.args.get("q", "").strip()
    sql = """
        SELECT
          s.student_id,
          s.name,
          c.class_name,
          COUNT(a.att_id) AS total_days,
          COALESCE(SUM(a.status = 'Present'), 0) AS present_days,
          CASE
            WHEN COUNT(a.att_id) = 0 THEN 0
            ELSE ROUND(100 * SUM(a.status = 'Present') / COUNT(a.att_id), 1)
          END AS percent
        FROM students s
        JOIN classes c ON c.class_id = s.class_id
        LEFT JOIN attendance a ON a.student_id = s.student_id
        WHERE 1=1
    """
    args = []
    if search:
        sql += " AND s.name LIKE %s"
        args.append(f"%{search}%")
    sql += " GROUP BY s.student_id, s.name, c.class_name ORDER BY s.student_id LIMIT 100"
    return jsonify(summary=query(sql, tuple(args)))


# ---------- FEES (paid vs unpaid status + pay fee) ----------
@app.route("/api/fees")
def fees():
    rows = query("""
        SELECT
          s.student_id,
          s.name,
          c.class_name,
          COALESCE(SUM(f.amount), 0) AS paid
        FROM students s
        JOIN classes c ON c.class_id = s.class_id
        LEFT JOIN fees f ON s.student_id = f.student_id
        GROUP BY s.student_id, s.name, c.class_name
        ORDER BY s.student_id
        LIMIT 100
    """)
    return jsonify(rows)


@app.route("/api/fees", methods=["POST"])
def pay_fee():
    d = request.get_json() or {}
    run(proc="pay_fee", args=(int(d["student_id"]), float(d["amount"])))
    return jsonify(ok=True)


if __name__ == "__main__":
    app.run(debug=True)