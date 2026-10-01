RG35XX A8 COMPATIBILITY TEST PACK
=================================

Muc dich:
- Cai harness test game J2ME moi vao SD.
- Tao launcher rieng cho tung JAR de chay truc tiep tu menu APPS.
- KHONG thay doi runtime A8 dang on dinh.
- Thu thap evidence rieng cho tung JAR.

YEU CAU
------
SD da co A8 production launcher:
Roms\APPS\RG35XX-AWEIGIT-R1.sh

BUOC 1 - CAI HARNESS
--------------------
1. Cam SD RG35XX vao PC.
2. Chay:
   INSTALL-A8-COMPAT-HARNESS.cmd
3. Nhap ky tu o SD, vi du:
   H
4. Neu thanh cong, SD se co:
   Roms\APPS\A8-COMPAT-RUN.sh
   A8-COMPAT-HARNESS-INSTALL-RESULT.txt

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
   - tao launcher trong Roms\APPS
5. Launcher co dang:
   A8-COMP-01-TEST.sh

Co the lap lai buoc nay cho nhieu JAR voi Candidate ID khac nhau.

BUOC 3 - CHAY TEST TREN RG35XX
------------------------------
1. Dua SD ve RG35XX.
2. Mo menu APPS.
3. Chay entry <CandidateId>-TEST tuong ung.
4. Harness se goi dung A8 production launcher va luu evidence tai:
   /mnt/mmc/A8-COMPAT-EVIDENCE/

Khong can go lenh shell thu cong.

BUOC 4 - THU THAP EVIDENCE
--------------------------
1. Tat may dung cach va thao SD.
2. Cam SD vao PC.
3. Chay:
   COLLECT-A8-COMPAT-EVIDENCE.cmd
4. Nhap ky tu o SD.
5. Mot file:
   A8-COMPAT-EVIDENCE-YYYYMMDD-HHMMSS.zip
   se duoc tao ngay trong thu muc test pack.
6. Upload ZIP do vao ChatGPT de phan tich.

TUY CHON - PREPARE RECORD TREN PC
---------------------------------
PREPARE-A8-CANDIDATE.ps1 van duoc giu de tao SHA256/record rieng neu can,
nhung REGISTER-A8-COMPAT-GAME.cmd da tu dong tinh SHA256 khi dang ky game tren SD.

NGUYEN TAC
----------
- A8 stable runtime khong duoc sua chi vi 1 game FAIL.
- Moi ket qua phai gan voi exact JAR filename + SHA256.
- Chi tao thay doi A9 neu loi tai hien duoc va xac dinh ro failure owner.
