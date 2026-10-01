RG35XX A8 COMPATIBILITY TEST PACK
=================================

Muc dich:
- Cai harness test game J2ME moi vao SD.
- KHONG thay doi runtime A8 dang on dinh.
- Thu thap evidence rieng cho tung JAR.

YEU CAU
------
SD da co A8 production launcher:
Roms\APPS\RG35XX-AWEIGIT-R1.sh

CAI HARNESS
-----------
1. Cam SD RG35XX vao PC.
2. Chay:
   INSTALL-A8-COMPAT-HARNESS.cmd
3. Nhap ky tu o SD, vi du:
   H
4. Neu thanh cong, SD se co:
   Roms\APPS\A8-COMPAT-RUN.sh
   A8-COMPAT-HARNESS-INSTALL-RESULT.txt

CHUAN BI GAME
-------------
Game JAR la input ben ngoai, KHONG nam trong goi nay.

Co the dung PREPARE-A8-CANDIDATE.ps1 de tao SHA256/record tren PC.

CHAY TEST TREN RG35XX
---------------------
Vi du game nam tai:
/mnt/mmc/Roms/JAVA/game.jar

Lenh:
sh /mnt/mmc/Roms/APPS/A8-COMPAT-RUN.sh "/mnt/mmc/Roms/JAVA/game.jar" "A8-COMP-01"

Evidence se duoc luu tai:
/mnt/mmc/A8-COMPAT-EVIDENCE/

SAU KHI TEST
------------
1. Tat may dung cach va thao SD.
2. Cam SD vao PC.
3. Chay:
   COLLECT-A8-COMPAT-EVIDENCE.cmd
4. Nhap ky tu o SD.
5. Mot file:
   A8-COMPAT-EVIDENCE-YYYYMMDD-HHMMSS.zip
   se duoc tao ngay trong thu muc test pack.
6. Upload ZIP do vao ChatGPT de phan tich.

NGUYEN TAC
----------
- A8 stable runtime khong duoc sua chi vi 1 game FAIL.
- Moi ket qua phai gan voi exact JAR filename + SHA256.
- Chi tao thay doi A9 neu loi tai hien duoc va xac dinh ro failure owner.
