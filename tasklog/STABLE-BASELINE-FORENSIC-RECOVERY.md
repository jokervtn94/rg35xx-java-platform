# Stable baseline forensic recovery

Status: EXACT-BINARY-RECOVERY-IN-PROGRESS / DEVICE-REVALIDATION-PENDING
Date: 2026-09-08

## Required identities

JamVM L Production:
`eea1b97cebfaca67b69ed365e966d80cdac22d8ff245c7a556137cfb2898ea34`

CN core:
`9c248b0b4bf4caf225861e1a8616f9585a09609c52aa60e78accaefb17e1cb40`

CQ runtime:
`45853d13376fd17d176a8296c247adcf2e14065cd44f171b1aaacf2387ec14a8`

Golden reference core:
`4ba55aeafba28379b8080a52f63cd64321867ac7af868cd3b43cc41a9165ecdf`

Golden reference runtime:
`de510e978ee0b601ac25c496197197676f86725662c434316825e00a86b497b8`

Rejected M1 core:
`f409396d489cd2b1aca3ce43b3c60dba90aae5a0305f9428629c8e1d88a57e87`

Rejected M1 runtime:
`cae779a1ac2dfd7cd65e8893b30fee8196c1c6107f693c335701fe34fea4d322`

## GitHub archaeology result

CN patch source is preserved in commit `7b7e91516d16a1988bae7bd907bacaecdf2fa972` and is fail-closed against three audited ARM instructions in the Golden core. Its Actions run is `34009805869`, artifact `9982106340`.

The artifact from that run is a source-build artifact, not the device-tested CN binary. Direct SHA verification produced core `9f154a096d52745406621e5ab0365eaa1768712305c4b9deb38723dfe2369523`, so it MUST NOT be substituted for CN `9c248b...`.

The Golden baseline documentation explicitly records that the original Golden binaries are not committed to the repository; hashes are the immutable identity. Therefore no regenerated or merely similar core/JAR may be labeled stable without exact SHA equality.

## Recovery policy

1. Search the entire RG35XX SD, all historical backup/snapshot directories, and ZIP archives for exact CN/CQ hashes.
2. Reject M1 hashes unconditionally.
3. Do not install an UNKNOWN_CANDIDATE.
4. Only when exact CN core + CQ runtime are both found may they be installed together with JamVM L.
5. Before installation, snapshot the current canonical JamVM/core/runtime paths.
6. Install both historical core aliases and both historical runtime JAR aliases, then verify SHA after copy.
7. If exact CN/CQ are unavailable, make no device changes and preserve the scan report for further recovery.

## Device state evidence before forensic scan

Latest SD scan found the rejected M1 runtime in both BIOS aliases, rejected M1 in the plus-core alias, and an unknown `28d03bf7...` core in the secondary alias. The existing backup also contains M1, so it is not a valid pre-M1 restore source.

## Acceptance

Do not mark STABLE or DEVICE-TEST-PASS until exact CN/CQ/JamVM-L are installed and KDTT boots, renders text/assets, passes the old JamVM crash point, and remains responsive on real RG35XX hardware.
