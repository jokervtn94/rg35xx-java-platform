#!/usr/bin/env python3
"""Audit-only staging helper for the P2B generic JDK8 text planner proof.

This does not modify runtime or production sources. It materializes a temporary,
package-relocated Java6-compatible copy of the exact JDK8u504 planner primitives
used by CI differential tests: Bidi, BidiUtils, ScriptRun and their narrow data
closure. Every non-package adaptation is anchored to exact source text.
"""
from pathlib import Path
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: stage_jdk8_text_planner_audit.py <jdk8u-root> <out-root>")

jdk = Path(sys.argv[1])
out = Path(sys.argv[2])
root = out / "src"

P_TEXT = "org.recompile.rg35xx.p2b.jdk8.text"
P_BIDI = "org.recompile.rg35xx.p2b.jdk8.bidi"
P_NORM = "org.recompile.rg35xx.p2b.jdk8.normalizer"
P_FONT = "org.recompile.rg35xx.p2b.jdk8.font"
changes = []


def read(rel):
    return (jdk / rel).read_text(encoding="utf-8")


def write(pkg, name, text):
    d = root / Path(pkg.replace(".", "/"))
    d.mkdir(parents=True, exist_ok=True)
    (d / name).write_text(text, encoding="utf-8")


def once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise SystemExit("P2B_PLANNER_STAGE_FAIL %s count=%d" % (label, count))
    changes.append(label)
    return text.replace(old, new, 1)


# java.text.Bidi -> private audit namespace.
s = read("jdk/src/share/classes/java/text/Bidi.java")
s = once(s, "package java.text;", "package %s;" % P_TEXT, "Bidi-package")
s = once(
    s,
    "import sun.text.bidi.BidiBase;",
    "import %s.BidiBase;\nimport java.text.AttributedCharacterIterator;\nimport java.text.AttributedString;" % P_BIDI,
    "Bidi-import-relocation",
)
write(P_TEXT, "Bidi.java", s)

# sun.text.bidi core. Only semantic-neutral Java6 syntax backport is multi-catch split.
for name in ("BidiBase.java", "BidiLine.java", "BidiRun.java"):
    s = read("jdk/src/share/classes/sun/text/bidi/" + name)
    s = once(s, "package sun.text.bidi;", "package %s;" % P_BIDI, name + "-package")
    if "import java.text.Bidi;" in s:
        s = once(s, "import java.text.Bidi;", "import %s.Bidi;" % P_TEXT, name + "-Bidi-import")
    if name == "BidiBase.java":
        for cls in ("UBiDiProps", "UCharacter", "UTF16"):
            s = once(
                s,
                "import sun.text.normalizer.%s;" % cls,
                "import %s.%s;" % (P_NORM, cls),
                name + "-" + cls + "-import",
            )
        old = """            } catch (NoSuchFieldException | IllegalAccessException x) {\n                throw new AssertionError(x);\n            }"""
        new = """            } catch (NoSuchFieldException x) {\n                throw new AssertionError(x);\n            } catch (IllegalAccessException x) {\n                throw new AssertionError(x);\n            }"""
        s = once(s, old, new, "BidiBase-Java6-multicatch-split")
    write(P_BIDI, name, s)

# Narrow normalizer closure used by UBiDiProps.
for name in ("UBiDiProps.java", "ICUData.java", "ICUBinary.java", "Trie.java", "CharTrie.java"):
    s = read("jdk/src/share/classes/sun/text/normalizer/" + name)
    s = once(s, "package sun.text.normalizer;", "package %s;" % P_NORM, name + "-package")
    if name == "CharTrie.java":
        dead = """    /**\n     * Java friend implementation\n     * To store the index and data array into the argument.\n     * @param friend java friend UCharacterProperty object to store the array\n     */\n    public void putIndexData(UCharacterProperty friend)\n    {\n        friend.setIndexData(m_friendAgent_);\n    }\n\n"""
        s = once(s, dead, "", "CharTrie-unreachable-UCharacterProperty-friend-excluded")
    write(P_NORM, name, s)

# UTF16 is exact source except calls to a one-method source extraction from UCharacterProperty.
s = read("jdk/src/share/classes/sun/text/normalizer/UTF16.java")
s = once(s, "package sun.text.normalizer;", "package %s;" % P_NORM, "UTF16-package")
needle = "UCharacterProperty.getRawSupplementary("
refs = s.count(needle)
if refs < 1:
    raise SystemExit("P2B_PLANNER_STAGE_FAIL UTF16 rawSupplementary refs=%d" % refs)
s = s.replace(needle, "rawSupplementary(")
pos = s.rfind("\n}")
if pos < 0:
    raise SystemExit("P2B_PLANNER_STAGE_FAIL UTF16 final brace")
helper = """
    /* Source-extracted from JDK8u504 UCharacterProperty.getRawSupplementary. */
    private static int rawSupplementary(char lead, char trail)
    {
        final int leadSurrogateShift = 10;
        final int surrogateOffset = SUPPLEMENTARY_MIN_VALUE -
            (SURROGATE_MIN_VALUE << leadSurrogateShift) - TRAIL_SURROGATE_MIN_VALUE;
        return (lead << leadSurrogateShift) + trail + surrogateOffset;
    }
"""
s = s[:pos] + helper + s[pos:]
changes.append("UTF16-source-extracted-rawSupplementary refs=%d" % refs)
write(P_NORM, "UTF16.java", s)

# Minimal UCharacter closure: exact constants/initialization/getDirection source extraction.
uchar = """package %s;

import java.io.IOException;

public final class UCharacter
{
    public static final int MAX_VALUE = UTF16.CODEPOINT_MAX_VALUE;
    private static final UBiDiProps gBdp;
    static
    {
        UBiDiProps bdp;
        try { bdp=UBiDiProps.getSingleton(); }
        catch(IOException e) { bdp=UBiDiProps.getDummy(); }
        gBdp=bdp;
    }
    private UCharacter() { }
    public static int getDirection(int ch) { return gBdp.getClass(ch); }
}
""" % P_NORM
write(P_NORM, "UCharacter.java", uchar)
changes.append("UCharacter-MAX_VALUE-and-direction-source-extraction")

# ScriptRun closure: exact source, package relocation only.
for name in ("Script.java", "ScriptRunData.java", "ScriptRun.java"):
    s = read("jdk/src/share/classes/sun/font/" + name)
    s = once(s, "package sun.font;", "package %s;" % P_FONT, name + "-package")
    write(P_FONT, name, s)

# BidiUtils: exact source, package relocation plus Bidi import relocation only.
s = read("jdk/src/share/classes/sun/font/BidiUtils.java")
s = once(s, "package sun.font;", "package %s;" % P_FONT, "BidiUtils-package")
s = once(s, "import java.text.Bidi;", "import %s.Bidi;" % P_TEXT, "BidiUtils-Bidi-import")
write(P_FONT, "BidiUtils.java", s)

# Fail-closed source anchors for every narrow extraction/removal.
uc = read("jdk/src/share/classes/sun/text/normalizer/UCharacter.java")
for anchor in (
    "public static final int MAX_VALUE = UTF16.CODEPOINT_MAX_VALUE;",
    "return gBdp.getClass(ch);",
    "bdp=UBiDiProps.getSingleton();",
    "bdp=UBiDiProps.getDummy();",
):
    if anchor not in uc:
        raise SystemExit("P2B_PLANNER_STAGE_FAIL UCharacter anchor " + anchor)
up = read("jdk/src/share/classes/sun/text/normalizer/UCharacterProperty.java")
if "return (lead << LEAD_SURROGATE_SHIFT_) + trail + SURROGATE_OFFSET_;" not in up:
    raise SystemExit("P2B_PLANNER_STAGE_FAIL rawSupplementary anchor")
ct = read("jdk/src/share/classes/sun/text/normalizer/CharTrie.java")
if ct.count("public void putIndexData(UCharacterProperty friend)") != 1:
    raise SystemExit("P2B_PLANNER_STAGE_FAIL CharTrie friend anchor")
ucp = read("jdk/src/share/classes/sun/text/normalizer/UCharacterProperty.java")
if ucp.count("m_trie_.putIndexData(this);") != 1:
    raise SystemExit("P2B_PLANNER_STAGE_FAIL UCharacterProperty friend call anchor")

status = [
    "P2B_TEXT_PLANNER_STAGE=PASS",
    "P2B_TEXT_PLANNER_BIDI_CORE_DELTA=PACKAGE_IMPORT_RELOCATION_PLUS_JAVA6_SYNTAX_ONLY",
    "P2B_TEXT_PLANNER_BIDIBASE_JAVA6_ADAPTATION=MULTICATCH_SPLIT_SAME_BODY",
    "P2B_TEXT_PLANNER_CHARTRIE_DELTA=UNREACHABLE_UCHARACTERPROPERTY_FRIEND_METHOD_EXCLUDED",
    "P2B_TEXT_PLANNER_UCHAR_DELTA=MAX_VALUE_PLUS_DIRECTION_SOURCE_EXTRACTION",
    "P2B_TEXT_PLANNER_UTF16_DELTA=RAW_SUPPLEMENTARY_SOURCE_EXTRACTION",
    "P2B_TEXT_PLANNER_SCRIPTRUN_DELTA=PACKAGE_DECLARATION_ONLY",
    "P2B_TEXT_PLANNER_BIDIUTILS_DELTA=PACKAGE_AND_BIDI_IMPORT_RELOCATION_ONLY",
    "P2B_TEXT_PLANNER_UNRELATED_UPROPS_UNORM_DATABASES=EXCLUDED",
    "P2B_TEXT_PLANNER_STAGE_CHANGE_COUNT=%d" % len(changes),
]
(out / "STAGE.txt").write_text("\n".join(status) + "\n", encoding="utf-8")
print("\n".join(status))
