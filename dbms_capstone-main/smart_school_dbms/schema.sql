-- DDL: Database creation & selection
DROP DATABASE IF EXISTS smart_school;
CREATE DATABASE smart_school CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smart_school;

-- DDL: Core tables
CREATE TABLE classes (
  class_id INT AUTO_INCREMENT PRIMARY KEY,
  class_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE subjects (
  subject_id INT AUTO_INCREMENT PRIMARY KEY,
  subject_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE admins (
  admin_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(120) UNIQUE,
  role_label VARCHAR(40) DEFAULT 'Admin'
);

CREATE TABLE teachers (
  teacher_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  subject_id INT,
  assigned_class VARCHAR(30),
  email VARCHAR(120),
  phone VARCHAR(20),
  monthly_salary DECIMAL(10,2) NOT NULL DEFAULT 45000.00,
  CONSTRAINT fk_teacher_subject FOREIGN KEY (subject_id)
    REFERENCES subjects(subject_id) ON DELETE SET NULL
);

CREATE TABLE students (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  class_id INT NOT NULL,
  roll_no INT,
  email VARCHAR(120),
  phone VARCHAR(20),
  CONSTRAINT fk_student_class FOREIGN KEY (class_id)
    REFERENCES classes(class_id) ON DELETE RESTRICT
);

CREATE TABLE marks (
  mark_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  subject_id INT NOT NULL,
  score INT NOT NULL,
  UNIQUE KEY uq_student_subject (student_id, subject_id),
  CONSTRAINT fk_mark_student FOREIGN KEY (student_id)
    REFERENCES students(student_id) ON DELETE CASCADE,
  CONSTRAINT fk_mark_subject FOREIGN KEY (subject_id)
    REFERENCES subjects(subject_id) ON DELETE CASCADE
);

CREATE TABLE attendance (
  att_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  att_date DATE NOT NULL,
  status ENUM('Present', 'Absent') NOT NULL,
  UNIQUE KEY uq_student_date (student_id, att_date),
  CONSTRAINT fk_att_student FOREIGN KEY (student_id)
    REFERENCES students(student_id) ON DELETE CASCADE
);

CREATE TABLE fees (
  fee_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  paid_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT fk_fee_student FOREIGN KEY (student_id)
    REFERENCES students(student_id) ON DELETE CASCADE
);

CREATE TABLE salaries (
  salary_id INT AUTO_INCREMENT PRIMARY KEY,
  teacher_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  paid_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT fk_sal_teacher FOREIGN KEY (teacher_id)
    REFERENCES teachers(teacher_id) ON DELETE CASCADE
);

CREATE TABLE results (
  student_id INT PRIMARY KEY,
  total_marks INT NOT NULL,
  avg_marks DECIMAL(5,2) NOT NULL,
  grade VARCHAR(5) NOT NULL,
  result VARCHAR(10) NOT NULL,
  CONSTRAINT fk_res_student FOREIGN KEY (student_id)
    REFERENCES students(student_id) ON DELETE CASCADE
);

CREATE TABLE audit_log (
  log_id INT AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(255) NOT NULL,
  log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- DDL: Indexes
CREATE INDEX idx_students_class_name ON students(class_id, name);
CREATE INDEX idx_teachers_subject ON teachers(subject_id);
CREATE INDEX idx_marks_score ON marks(score);
CREATE INDEX idx_att_student_status ON attendance(student_id, status);
CREATE INDEX idx_fees_student ON fees(student_id);
CREATE INDEX idx_salaries_teacher ON salaries(teacher_id);

-- DML: Admin
INSERT INTO admins (name, email, role_label) VALUES
('Principal Rao', 'admin@school.in', 'Admin');

-- DML: Subjects (from teachers in CSV)
INSERT INTO subjects (subject_name) VALUES
('Maths'),
('Science'),
('English'),
('Hindi'),
('Social Studies'),
('Computer');

-- DML: Classes (30 sections from students in CSV: Class 6-A .. Class 10-F)
INSERT INTO classes (class_name) VALUES
('Class 6-A'),('Class 6-B'),('Class 6-C'),('Class 6-D'),('Class 6-E'),('Class 6-F'),
('Class 7-A'),('Class 7-B'),('Class 7-C'),('Class 7-D'),('Class 7-E'),('Class 7-F'),
('Class 8-A'),('Class 8-B'),('Class 8-C'),('Class 8-D'),('Class 8-E'),('Class 8-F'),
('Class 9-A'),('Class 9-B'),('Class 9-C'),('Class 9-D'),('Class 9-E'),('Class 9-F'),
('Class 10-A'),('Class 10-B'),('Class 10-C'),('Class 10-D'),('Class 10-E'),('Class 10-F');

-- DML: 30 Teachers (from all-logins.csv, role='teacher')
INSERT INTO teachers (name, subject_id, assigned_class, email, phone, monthly_salary) VALUES
('Mrs. Anita Kaur', (SELECT subject_id FROM subjects WHERE subject_name='Maths'), 'Class 6', 'anita.kaur@school.in', '9810000101', 48000.00),
('Mr. Rajesh Reddy', (SELECT subject_id FROM subjects WHERE subject_name='Maths'), 'Class 7', 'rajesh.reddy@school.in', '9810000102', 49000.00),
('Mrs. Sunita Iyer', (SELECT subject_id FROM subjects WHERE subject_name='Maths'), 'Class 8', 'sunita.iyer@school.in', '9810000103', 50000.00),
('Mr. Vikram Mehta', (SELECT subject_id FROM subjects WHERE subject_name='Maths'), 'Class 9', 'vikram.mehta@school.in', '9810000104', 52000.00),
('Mrs. Neha Bose', (SELECT subject_id FROM subjects WHERE subject_name='Maths'), 'Class 10', 'neha.bose@school.in', '9810000105', 54000.00),
('Mr. Suresh Fernandes', (SELECT subject_id FROM subjects WHERE subject_name='Science'), 'Class 6', 'suresh.fernandes@school.in', '9810000106', 48000.00),
('Mrs. Pooja Joshi', (SELECT subject_id FROM subjects WHERE subject_name='Science'), 'Class 7', 'pooja.joshi@school.in', '9810000107', 49000.00),
('Mr. Amit Chauhan', (SELECT subject_id FROM subjects WHERE subject_name='Science'), 'Class 8', 'amit.chauhan@school.in', '9810000108', 50000.00),
('Mrs. Kavita Pillai', (SELECT subject_id FROM subjects WHERE subject_name='Science'), 'Class 9', 'kavita.pillai@school.in', '9810000109', 52000.00),
('Mr. Manoj Khanna', (SELECT subject_id FROM subjects WHERE subject_name='Science'), 'Class 10', 'manoj.khanna@school.in', '9810000110', 54000.00),
('Mrs. Rekha Sharma', (SELECT subject_id FROM subjects WHERE subject_name='English'), 'Class 6', 'rekha.sharma@school.in', '9810000111', 46000.00),
('Mr. Sanjay Verma', (SELECT subject_id FROM subjects WHERE subject_name='English'), 'Class 7', 'sanjay.verma@school.in', '9810000112', 47000.00),
('Mrs. Deepa Nair', (SELECT subject_id FROM subjects WHERE subject_name='English'), 'Class 8', 'deepa.nair@school.in', '9810000113', 48500.00),
('Mr. Arun Gupta', (SELECT subject_id FROM subjects WHERE subject_name='English'), 'Class 9', 'arun.gupta@school.in', '9810000114', 50500.00),
('Mrs. Meena Das', (SELECT subject_id FROM subjects WHERE subject_name='English'), 'Class 10', 'meena.das@school.in', '9810000115', 52500.00),
('Mr. Rahul Malik', (SELECT subject_id FROM subjects WHERE subject_name='Hindi'), 'Class 6', 'rahul.malik@school.in', '9810000116', 45000.00),
('Mrs. Shweta Patel', (SELECT subject_id FROM subjects WHERE subject_name='Hindi'), 'Class 7', 'shweta.patel@school.in', '9810000117', 46000.00),
('Mr. Prakash Rao', (SELECT subject_id FROM subjects WHERE subject_name='Hindi'), 'Class 8', 'prakash.rao@school.in', '9810000118', 47500.00),
('Mrs. Geeta Saxena', (SELECT subject_id FROM subjects WHERE subject_name='Hindi'), 'Class 9', 'geeta.saxena@school.in', '9810000119', 49000.00),
('Mr. Naveen Bhatt', (SELECT subject_id FROM subjects WHERE subject_name='Hindi'), 'Class 10', 'naveen.bhatt@school.in', '9810000120', 51000.00),
('Mrs. Lata Menon', (SELECT subject_id FROM subjects WHERE subject_name='Social Studies'), 'Class 6', 'lata.menon@school.in', '9810000121', 46000.00),
('Mr. Vivek Kapoor', (SELECT subject_id FROM subjects WHERE subject_name='Social Studies'), 'Class 7', 'vivek.kapoor@school.in', '9810000122', 47000.00),
('Mrs. Anjali Chopra', (SELECT subject_id FROM subjects WHERE subject_name='Social Studies'), 'Class 8', 'anjali.chopra@school.in', '9810000123', 48500.00),
('Mr. Harish Singh', (SELECT subject_id FROM subjects WHERE subject_name='Social Studies'), 'Class 9', 'harish.singh@school.in', '9810000124', 50000.00),
('Mrs. Usha Mishra', (SELECT subject_id FROM subjects WHERE subject_name='Social Studies'), 'Class 10', 'usha.mishra@school.in', '9810000125', 52000.00),
('Mr. Dinesh Pandey', (SELECT subject_id FROM subjects WHERE subject_name='Computer'), 'Class 6', 'dinesh.pandey@school.in', '9810000126', 47500.00),
('Mrs. Seema Tiwari', (SELECT subject_id FROM subjects WHERE subject_name='Computer'), 'Class 7', 'seema.tiwari@school.in', '9810000127', 48500.00),
('Mr. Mukesh Agarwal', (SELECT subject_id FROM subjects WHERE subject_name='Computer'), 'Class 8', 'mukesh.agarwal@school.in', '9810000128', 50000.00),
('Mrs. Priti Banerjee', (SELECT subject_id FROM subjects WHERE subject_name='Computer'), 'Class 9', 'priti.banerjee@school.in', '9810000129', 51500.00),
('Mr. Ashok Desai', (SELECT subject_id FROM subjects WHERE subject_name='Computer'), 'Class 10', 'ashok.desai@school.in', '9810000130', 53500.00);

-- DML: 1,200 Students (from all-logins.csv, role='student', parents excluded)
-- Tip: In MySQL client, you can also load all 1,200 rows directly from CSV or run the INSERTs below.
INSERT INTO students (name, class_id, roll_no, email, phone)
SELECT
  name,
  (SELECT class_id FROM classes WHERE class_name = TRIM(SUBSTRING_INDEX(details, ' roll ', 1))),
  CAST(TRIM(SUBSTRING_INDEX(details, ' roll ', -1)) AS UNSIGNED),
  email,
  CONCAT('97', LPAD(ROW_NUMBER() OVER (ORDER BY name, details), 8, '0'))
FROM (
  -- Sample first batch + full 1,200 rows from all-logins.csv:
  SELECT 'Sana Kapoor' AS name, 'Class 6-A roll 1' AS details, 'sana.kapoor.6a1@school.in' AS email UNION ALL
  SELECT 'Dev Agarwal', 'Class 6-A roll 2', 'dev.agarwal.6a2@school.in' UNION ALL
  SELECT 'Zoya Soni', 'Class 6-A roll 3', 'zoya.soni.6a3@school.in' UNION ALL
  SELECT 'Rudra Iyer', 'Class 6-A roll 4', 'rudra.iyer.6a4@school.in' UNION ALL
  SELECT 'Myra Tiwari', 'Class 6-A roll 5', 'myra.tiwari.6a5@school.in' UNION ALL
  SELECT 'Parth Rathore', 'Class 6-A roll 6', 'parth.rathore.6a6@school.in' UNION ALL
  SELECT 'Trisha Mehta', 'Class 6-A roll 7', 'trisha.mehta.6a7@school.in' UNION ALL
  SELECT 'Ayaan Pandey', 'Class 6-A roll 8', 'ayaan.pandey.6a8@school.in' UNION ALL
  SELECT 'Meera Dubey', 'Class 6-A roll 9', 'meera.dubey.6a9@school.in' UNION ALL
  SELECT 'Arjun Joshi', 'Class 6-A roll 10', 'arjun.joshi.6a10@school.in' UNION ALL
  SELECT 'Jiya Nair', 'Class 10-F roll 31', 'jiya.nair.10f31@school.in' UNION ALL
  SELECT 'Rohan Rao', 'Class 10-F roll 32', 'rohan.rao.10f32@school.in' UNION ALL
  SELECT 'Kavya Shetty', 'Class 10-F roll 33', 'kavya.shetty.10f33@school.in' UNION ALL
  SELECT 'Krish Singh', 'Class 10-F roll 34', 'krish.singh.10f34@school.in' UNION ALL
  SELECT 'Ira Chopra', 'Class 10-F roll 35', 'ira.chopra.10f35@school.in' UNION ALL
  SELECT 'Shaurya Desai', 'Class 10-F roll 36', 'shaurya.desai.10f36@school.in' UNION ALL
  SELECT 'Saanvi Verma', 'Class 10-F roll 37', 'saanvi.verma.10f37@school.in' UNION ALL
  SELECT 'Veer Bose', 'Class 10-F roll 38', 'veer.bose.10f38@school.in' UNION ALL
  SELECT 'Bhavya Banerjee', 'Class 10-F roll 39', 'bhavya.banerjee.10f39@school.in' UNION ALL
  SELECT 'Aarav Sharma', 'Class 10-F roll 40', 'aarav.sharma.10f40@school.in'
) AS seed_batch;

-- Populate remaining students across all 30 classes (40 per class = 1,200 total) if fewer than 1,200 exist
DROP PROCEDURE IF EXISTS seed_full_1200_students;
DELIMITER //
CREATE PROCEDURE seed_full_1200_students()
BEGIN
  DECLARE v_cid INT DEFAULT 1;
  DECLARE v_r INT DEFAULT 1;
  DECLARE v_cname VARCHAR(30);
  DECLARE v_fname VARCHAR(40);
  DECLARE v_lname VARCHAR(40);
  DECLARE v_idx INT DEFAULT 0;

  WHILE v_cid <= 30 DO
    SELECT class_name INTO v_cname FROM classes WHERE class_id = v_cid;
    SET v_r = 1;
    WHILE v_r <= 40 DO
      SET v_idx = (v_cid - 1) * 40 + v_r;
      SET v_fname = ELT(((v_idx - 1) % 12) + 1,
        'Aarav','Diya','Kabir','Ananya','Rohan','Ishita','Vivaan','Kiara','Advait','Tara','Reyansh','Naina');
      SET v_lname = ELT(((v_idx * 3) % 12) + 1,
        'Sharma','Verma','Kapoor','Nair','Mehta','Iyer','Joshi','Gupta','Rao','Singh','Desai','Bhatt');
      INSERT INTO students (name, class_id, roll_no, email, phone)
      SELECT CONCAT(v_fname, ' ', v_lname), v_cid, v_r,
             LOWER(CONCAT(v_fname, '.', v_lname, '.', v_cid, 'r', v_r, '@school.in')),
             CONCAT('98', LPAD(v_idx, 8, '0'))
      FROM DUAL
      WHERE NOT EXISTS (
        SELECT 1 FROM students WHERE class_id = v_cid AND roll_no = v_r
      );
      SET v_r = v_r + 1;
    END WHILE;
    SET v_cid = v_cid + 1;
  END WHILE;
END //
DELIMITER ;

CALL seed_full_1200_students();
DROP PROCEDURE seed_full_1200_students;

-- DML: Sample Marks across students & all 6 subjects
INSERT INTO marks (student_id, subject_id, score)
SELECT
  s.student_id,
  sub.subject_id,
  GREATEST(25, LEAST(99, 45 + ((s.student_id * 7 + sub.subject_id * 11) % 52)))
FROM students s
CROSS JOIN subjects sub
WHERE s.student_id <= 150;

-- DML: Sample Attendance across students
INSERT INTO attendance (student_id, att_date, status)
SELECT
  s.student_id,
  DATE_SUB(CURRENT_DATE, INTERVAL d.n DAY),
  IF(((s.student_id + d.n * 3) % 7) = 0, 'Absent', 'Present')
FROM students s
JOIN (
  SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
) d
WHERE s.student_id <= 150;

-- DML: Sample Fees (some paid, some unpaid)
INSERT INTO fees (student_id, amount, paid_on)
SELECT
  s.student_id,
  15000.00,
  DATE_SUB(CURRENT_DATE, INTERVAL (s.student_id % 15) DAY)
FROM students s
WHERE s.student_id <= 90 AND (s.student_id % 3) <> 0;

-- DML: Sample Salaries (first 18 teachers paid, remaining 12 pending)
INSERT INTO salaries (teacher_id, amount, paid_on)
SELECT
  t.teacher_id,
  t.monthly_salary,
  DATE_SUB(CURRENT_DATE, INTERVAL (t.teacher_id % 10) DAY)
FROM teachers t
WHERE t.teacher_id <= 18;

-- Views
CREATE OR REPLACE VIEW v_student_details AS
SELECT
  s.student_id,
  s.name,
  s.class_id,
  c.class_name,
  s.roll_no,
  s.phone,
  s.email
FROM students s
JOIN classes c ON c.class_id = s.class_id;

CREATE OR REPLACE VIEW v_student_total AS
SELECT
  s.student_id,
  s.name,
  s.class_id,
  c.class_name,
  COALESCE(SUM(m.score), 0) AS total,
  ROUND(COALESCE(AVG(m.score), 0), 2) AS avg_score
FROM students s
JOIN classes c ON c.class_id = s.class_id
LEFT JOIN marks m ON m.student_id = s.student_id
GROUP BY s.student_id, s.name, s.class_id, c.class_name;

CREATE OR REPLACE VIEW v_teacher_salary_status AS
SELECT
  t.teacher_id,
  t.name,
  t.subject_id,
  COALESCE(sub.subject_name, 'Unassigned') AS subject_name,
  t.assigned_class,
  t.phone,
  t.monthly_salary,
  COALESCE(SUM(sal.amount), 0) AS paid_amount,
  CASE WHEN COALESCE(SUM(sal.amount), 0) > 0 THEN 'Paid' ELSE 'Pending' END AS salary_status
FROM teachers t
LEFT JOIN subjects sub ON sub.subject_id = t.subject_id
LEFT JOIN salaries sal ON sal.teacher_id = t.teacher_id
GROUP BY t.teacher_id, t.name, t.subject_id, sub.subject_name, t.assigned_class, t.phone, t.monthly_salary;

-- Stored Function
DROP FUNCTION IF EXISTS fn_grade;
DELIMITER //
CREATE FUNCTION fn_grade(p_total INT) RETURNS VARCHAR(5)
DETERMINISTIC
BEGIN
  DECLARE v_pct DECIMAL(6,2);
  SET v_pct = p_total / 6.0;
  IF v_pct >= 90 THEN RETURN 'A+';
  ELSEIF v_pct >= 75 THEN RETURN 'A';
  ELSEIF v_pct >= 60 THEN RETURN 'B';
  ELSEIF v_pct >= 40 THEN RETURN 'C';
  ELSE RETURN 'F';
  END IF;
END //
DELIMITER ;

-- Triggers
DROP TRIGGER IF EXISTS trg_check_marks;
DELIMITER //
CREATE TRIGGER trg_check_marks
BEFORE INSERT ON marks
FOR EACH ROW
BEGIN
  IF NEW.score < 0 OR NEW.score > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Marks must be between 0 and 100.';
  END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trg_check_marks_update;
DELIMITER //
CREATE TRIGGER trg_check_marks_update
BEFORE UPDATE ON marks
FOR EACH ROW
BEGIN
  IF NEW.score < 0 OR NEW.score > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Marks must be between 0 and 100.';
  END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trg_student_deleted;
DELIMITER //
CREATE TRIGGER trg_student_deleted
AFTER DELETE ON students
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(action)
  VALUES (CONCAT('Deleted student #', OLD.student_id, ' (', OLD.name, ')'));
END //
DELIMITER ;

-- Stored Procedures (including Cursor & TCL Transactions)
DROP PROCEDURE IF EXISTS add_student;
DELIMITER //
CREATE PROCEDURE add_student(IN p_name VARCHAR(100), IN p_class_id INT, IN p_phone VARCHAR(20))
BEGIN
  DECLARE v_next_roll INT;
  SELECT COALESCE(MAX(roll_no), 0) + 1 INTO v_next_roll FROM students WHERE class_id = p_class_id;
  INSERT INTO students(name, class_id, roll_no, phone) VALUES (p_name, p_class_id, v_next_roll, p_phone);
  INSERT INTO audit_log(action) VALUES (CONCAT('Added student: ', p_name, ' (Class ID ', p_class_id, ')'));
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS add_teacher;
DELIMITER //
CREATE PROCEDURE add_teacher(
  IN p_name VARCHAR(100),
  IN p_subject_id INT,
  IN p_class VARCHAR(30),
  IN p_phone VARCHAR(20),
  IN p_salary DECIMAL(10,2)
)
BEGIN
  INSERT INTO teachers(name, subject_id, assigned_class, phone, monthly_salary)
  VALUES (p_name, p_subject_id, p_class, p_phone, IFNULL(p_salary, 45000.00));
  INSERT INTO audit_log(action) VALUES (CONCAT('Added teacher: ', p_name));
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS pay_fee;
DELIMITER //
CREATE PROCEDURE pay_fee(IN p_student_id INT, IN p_amount DECIMAL(10,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fee amount must be greater than 0. Transaction rolled back.';
  END IF;
  INSERT INTO fees(student_id, amount) VALUES (p_student_id, p_amount);
  INSERT INTO audit_log(action) VALUES (CONCAT('Fee paid: Rs.', p_amount, ' for student #', p_student_id));
  COMMIT;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS pay_salary;
DELIMITER //
CREATE PROCEDURE pay_salary(IN p_teacher_id INT, IN p_amount DECIMAL(10,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary amount must be greater than 0. Transaction rolled back.';
  END IF;
  INSERT INTO salaries(teacher_id, amount) VALUES (p_teacher_id, p_amount);
  INSERT INTO audit_log(action) VALUES (CONCAT('Salary paid: Rs.', p_amount, ' for teacher #', p_teacher_id));
  COMMIT;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS generate_results;
DELIMITER //
CREATE PROCEDURE generate_results()
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE v_sid INT;
  DECLARE v_tot INT;
  DECLARE v_avg DECIMAL(5,2);
  DECLARE v_grade VARCHAR(5);
  DECLARE v_res VARCHAR(10);

  DECLARE cur_students CURSOR FOR
    SELECT student_id, COALESCE(SUM(score), 0)
    FROM students
    LEFT JOIN marks USING (student_id)
    GROUP BY student_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur_students;
  read_loop: LOOP
    FETCH cur_students INTO v_sid, v_tot;
    IF done THEN
      LEAVE read_loop;
    END IF;
    SET v_avg = ROUND(v_tot / 6.0, 2);
    SET v_grade = fn_grade(v_tot);
    SET v_res = IF(v_avg >= 40, 'Pass', 'Fail');

    INSERT INTO results(student_id, total_marks, avg_marks, grade, result)
    VALUES (v_sid, v_tot, v_avg, v_grade, v_res)
    ON DUPLICATE KEY UPDATE
      total_marks = VALUES(total_marks),
      avg_marks = VALUES(avg_marks),
      grade = VALUES(grade),
      result = VALUES(result);
  END LOOP;
  CLOSE cur_students;
END //
DELIMITER ;

-- DCL: Role/user privileges example (run as DBA if needed)
-- CREATE USER IF NOT EXISTS 'school_app'@'localhost' IDENTIFIED BY 'SchoolPass@123';
-- GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON smart_school.* TO 'school_app'@'localhost';
-- FLUSH PRIVILEGES;

USE smart_school;
