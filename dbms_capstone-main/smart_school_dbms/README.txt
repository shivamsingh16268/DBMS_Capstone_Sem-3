SMART SCHOOL - SETUP

1) MySQL 8.0.31+ install karo (INTERSECT/EXCEPT isi version ke baad chalte hain)
2) Is folder mein terminal kholo aur chalao:
      mysql -u root -p < schema.sql
   (ya MySQL Workbench mein schema.sql open karke Run karo)
3) pip install -r requirements.txt
4) app.py mein YOUR_PASSWORD ki jagah apna MySQL password likho
5) python app.py
6) Browser mein kholo:  http://127.0.0.1:5000
   (index.html ko double-click karke MAT kholo, wo backend ke bina kaam nahi karega)
