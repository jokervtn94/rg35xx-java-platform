#!/usr/bin/env python3
import pathlib,re,sys
if len(sys.argv)!=3:
    raise SystemExit('usage: vc7r22r13g_apply_input_consumption_trace.py <MobilePlatform.java> <Display.java>')
mp=pathlib.Path(sys.argv[1]); disp=pathlib.Path(sys.argv[2])
M=mp.read_text(encoding='utf-8'); D=disp.read_text(encoding='utf-8')
orig=(M,D)

def once(s,old,new,label):
    n=s.count(old)
    if n!=1: raise SystemExit('R13G %s anchor count=%d'%(label,n))
    return s.replace(old,new,1)

# R1.3F bytecode proves the gap after SC_PREV_READ_DONE is the existing early-return
# `next == null || current == next`. Split that condition only to log the exact reason;
# behavior remains equivalent.
pat=r'if\s*\(\s*next\s*==\s*null\s*\|\|\s*current\s*==\s*next\s*\)\s*\{\s*return;\s*\}'
rep='''if(next == null)\n\t\t\t\t{\n\t\t\t\t\trg35xxR13ELog("SC_EARLY_RETURN_NULL", rg35xxR13ESetCurrentSeq, 0);\n\t\t\t\t\treturn;\n\t\t\t\t}\n\t\t\t\tif(current == next)\n\t\t\t\t{\n\t\t\t\t\trg35xxR13ELog("SC_EARLY_RETURN_SAME", rg35xxR13ESetCurrentSeq, 1);\n\t\t\t\t\treturn;\n\t\t\t\t}'''
D,n=re.subn(pat,rep,D,count=1,flags=re.S)
if n!=1: raise SystemExit('R13G setCurrent early-return anchor count=%d'%n)

# R1.3E only showed that the MobilePlatform delivery runnable completed. It did not
# distinguish a key consumed by command handling from a key actually delivered to the
# MIDlet Canvas. Preserve exactly one handleCommands evaluation and log the result.
M=once(M,
'''\t\t\t\t\t\tif(!handleCommands(Mobile.getCanvasAction(keycode)))\n\t\t\t\t\t\t{''',
'''\t\t\t\t\t\tboolean rg35xxR13GHandled = handleCommands(Mobile.getCanvasAction(keycode));\n\t\t\t\t\t\trg35xxR13ELog("MP_COMMAND_RESULT", rg35xxR13EDeliverSeq, rg35xxR13GHandled ? 1 : 0);\n\t\t\t\t\t\tif(!rg35xxR13GHandled)\n\t\t\t\t\t\t{''','command result')

M=once(M,
'''\t\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed()) { displayable.keyPressed(keycode); }''',
'''\t\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed())\n\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\trg35xxR13ELog("MP_GAME_KEYPRESS_BEGIN", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t\t\t\tdisplayable.keyPressed(keycode);\n\t\t\t\t\t\t\t\trg35xxR13ELog("MP_GAME_KEYPRESS_DONE", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t\t\t}''','game keypress')

M=once(M,
'''\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed()) { displayable.keyReleased(keycode); }''',
'''\t\t\t\t\t\tif(displayable instanceof Canvas && !((Canvas) displayable).areKeysSuppressed())\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\trg35xxR13ELog("MP_GAME_KEYRELEASE_BEGIN", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t\t\tdisplayable.keyReleased(keycode);\n\t\t\t\t\t\t\trg35xxR13ELog("MP_GAME_KEYRELEASE_DONE", rg35xxR13EDeliverSeq, keycode);\n\t\t\t\t\t\t}''','game keyrelease')

for tok in ('MP_COMMAND_RESULT','MP_GAME_KEYPRESS_BEGIN','MP_GAME_KEYPRESS_DONE','MP_GAME_KEYRELEASE_BEGIN','MP_GAME_KEYRELEASE_DONE'):
    if tok not in M: raise SystemExit('R13G MobilePlatform marker missing '+tok)
for tok in ('SC_EARLY_RETURN_NULL','SC_EARLY_RETURN_SAME'):
    if tok not in D: raise SystemExit('R13G Display marker missing '+tok)
if (M,D)==orig: raise SystemExit('R13G no mutation')
mp.write_text(M,encoding='utf-8',newline='\n'); disp.write_text(D,encoding='utf-8',newline='\n')
print('VC7R22-R1.3G_INPUT_CONSUMPTION_TRACE=PASS')
print('BEHAVIOR_CHANGE=NONE_TRACE_ONLY_EQUIVALENT_EARLY_RETURN_SPLIT')
