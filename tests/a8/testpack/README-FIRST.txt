RG35XX A8 COMPATIBILITY TEST PACK R3
====================================

Muc dich:
- Cai harness test game J2ME moi vao SD.
- Tu nhan dien layout A8 da co tren SD bang exact SHA256.
- Tao launcher rieng cho tung JAR de chay truc tiep tu menu APPS.
- KHONG sua runtime A8 dang co.
- Thu thap evidence/diagnostic rieng cho tung JAR.

R3 KHAC R2
----------
R2 bat buoc phai co:
Roms\APPS\RG35XX-AWEIGIT-R1.sh

R3 khong con phu thuoc ten launcher nay.
Neu launcher canonical khong co, R3 se:
1. Kiem tra JamVM + glibj dung protected SHA256 A8.
2. Quet Roms\APPS de tim payload co du 5 file A8.
3. Chi chap nhan payload khi TOAN BO SHA256 khop baseline A8.
4. Tao A8-COMPAT-PRODUCTION-BRIDGE.sh tro toi payload da xac minh.

Neu khong tim thay exact A8, R3 KHONG tu sua hay suy dien build.
No se tao:
A8-COMPAT-SD-DIAGNOSTIC.txt
Tai goc SD de gui lai phan tich.

BUOC 1 - CAI HARNESS
--------------------
1. Cam SD RG35XX vao PC.
2. Chay:
   INSTALL-A8-COMPAT-HARNESS.cmd
3. Nhap ky tu o SD, vi du:
   H
4. Neu PASS, SD se co:
   Roms\APPS\A8-COMPAT-RUN.sh
   A8-COMPAT-HARNESS-INSTALL-RESULT.txt
   A8-COMPAT-SD-DIAGNOSTIC.txt
5. Neu launcher canonical khong co nhung exact A8 payload duoc tim thay, SD se co them:
   Roms\APPS\A8-COMPAT-PRODUCTION-BRIDGE.sh

BUOC 2 - DANG KY GAME TEST
--------------------------
Game JAR la input ben ngoai, KHONG nam trong goi nay.

1. Copy JAR vao SD, vi du:
   H:\Roms\JAVA\game.jar
2. Chay:
   REGISTER-A8-COMPAT-GAME.cmd
3. Nhap:
   - ky tu o SD, vi du H
   - duong dan JAR tren SD
   - Candidate ID, vi du A8-COMP-01
4. Tool se:
   - tinh exact JAR SHA256
   - tao candidate record
   - doi duong dan Windows sang /mnt/mmc/... dung format RG35XX
   - tao launcher trong Roms\APPS
5. Launcher co dang:
   A8-COMP-01-TEST.sh

BUOC 3 - CHAY TEST TREN RG35XX
------------------------------
1. Dua SD ve RG35XX.
2. Mo menu APPS.
3. Chay entry <CandidateId>-TEST tuong ung.
4. Harness se su dung:
   - canonical A8 launcher neu co; hoac
   - verified A8 payload bridge neu R3 da xac minh payload bang SHA256.
5. Evidence luu tai:
   /mnt/mmc/A8-COMPAT-EVIDENCE/

Khong can go lenh shell thu cong.

BUOC 4 - THU THAP EVIDENCE / DIAGNOSTIC
----------------------------------------
1. Tat may dung cach va thao SD.
2. Cam SD vao PC.
3. Chay:
   COLLECT-A8-COMPAT-EVIDENCE.cmd
4. Nhap ky tu o SD.
5. Mot file:
   A8-COMPAT-EVIDENCE-YYYYMMDD-HHMMSS.zip
   se duoc tao ngay trong thu muc test pack.
6. Collector R3 gom ca:
   - evidence game neu da test
   - candidate records
   - install result
   - A8-COMPAT-SD-DIAGNOSTIC.txt
   - runtime result neu co
7. Upload ZIP do vao ChatGPT de phan tich.

Neu BUOC 1 FAIL
---------------
Khong can tu sua SD.
Chay COLLECT-A8-COMPAT-EVIDENCE.cmd ngay sau do.
R3 co the gom diagnostic ngay ca khi chua chay game.

NGUYEN TAC
----------
- Khong chap nhan payload chi dua vao ten thu muc/file.
- A8 payload phai khop exact protected hashes.
- Existing runtime files khong bi sua.
- A8 stable runtime khong duoc sua chi vi 1 game FAIL.
- Moi ket qua phai gan voi exact JAR filename + SHA256.
- Chi tao A9 khi loi tai hien duoc va xac dinh ro failure owner.
