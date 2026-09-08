#!/usr/bin/env python3
import pathlib, sys
p=pathlib.Path(sys.argv[1]); s=p.read_text(); orig=s
s=s.replace('#include <unistd.h>\n','#include <unistd.h>\n#include <stdio.h>\n#include <stdarg.h>\n#include <time.h>\n',1)
marker='static struct rg35xx_golden_state g;\n'
diag=r'''
static void rg35xx_diag(const char *fmt, ...)
{
    FILE *f = fopen("/mnt/mmc/freej2me-core.log", "a");
    va_list ap;
    if(!f) return;
    fprintf(f, "RG35XX-GOLDEN-DIAG: ");
    va_start(ap, fmt); vfprintf(f, fmt, ap); va_end(ap);
    fputc('\n', f); fflush(f); fclose(f);
}
'''
assert marker in s; s=s.replace(marker,marker+diag,1)
s=s.replace('    while(g.run)\n    {\n        unsigned w, h, rotation;', '    rg35xx_diag("receiver thread entered read_fd=%d write_fd=%d", g.read_fd, g.write_fd);\n    while(g.run)\n    {\n        unsigned w, h, rotation;',1)
s=s.replace('        if(!write_exact(g.write_fd, request, sizeof(request))) break;\n        if(!read_header_resync(header, &w, &h, &rotation)) break;', '        if(!write_exact(g.write_fd, request, sizeof(request))) { rg35xx_diag("frame request write FAILED errno=%d", errno); break; }\n        rg35xx_diag("frame request sent");\n        if(!read_header_resync(header, &w, &h, &rotation)) { rg35xx_diag("frame header read FAILED errno=%d", errno); break; }\n        rg35xx_diag("frame header OK w=%u h=%u rot=%u", w, h, rotation);',1)
s=s.replace('        if(read_exact(g.read_fd, g.wire_payload, payload) <= 0) break;', '        if(read_exact(g.read_fd, g.wire_payload, payload) <= 0) { rg35xx_diag("frame payload read FAILED bytes=%lu errno=%d", (unsigned long)payload, errno); break; }\n        rg35xx_diag("frame payload OK bytes=%lu", (unsigned long)payload);',1)
s=s.replace('        publish_back(w, h, rotation, header);', '        publish_back(w, h, rotation, header);\n        if(g.generation <= 3ul) rg35xx_diag("frame published generation=%lu", g.generation);',1)
s=s.replace('    g.run = 0;\n    return NULL;', '    rg35xx_diag("receiver thread EXIT generation=%lu", g.generation);\n    g.run = 0;\n    return NULL;',1)
s=s.replace('    if(pthread_mutex_init(&g.mutex, NULL) != 0) return 0;', '    if(pthread_mutex_init(&g.mutex, NULL) != 0) { rg35xx_diag("video init mutex FAILED"); return 0; }\n    rg35xx_diag("video init OK read_fd=%d write_fd=%d output=%ux%u", read_fd, write_fd, output_width, output_height);',1)
s=s.replace('    if(pthread_create(&g.thread, NULL, receiver_main, NULL) != 0)', '    rg35xx_diag("video start requested");\n    if(pthread_create(&g.thread, NULL, receiver_main, NULL) != 0)',1)
s=s.replace('    g.started = 1;\n    return 1;', '    g.started = 1;\n    rg35xx_diag("video start OK");\n    return 1;',1)
s=s.replace('    if(g.snapshot.rotation == 0)\n        blit_nearest(&g.snapshot);\n    else\n        return 0;', '    if(g.snapshot.rotation == 0)\n        blit_nearest(&g.snapshot);\n    else { rg35xx_diag("present rejected rotation=%u generation=%lu", g.snapshot.rotation, generation); return 0; }',1)
s=s.replace('    g.presented_generation = generation;\n    return 1;', '    if(g.presented_generation == 0 || generation <= 3ul) rg35xx_diag("present OK generation=%lu src=%ux%u", generation, g.snapshot.width, g.snapshot.height);\n    g.presented_generation = generation;\n    return 1;',1)
if s==orig: raise SystemExit('no mutation')
p.write_text(s)
print('GOLDEN BLACK SCREEN DIAG PASS',p)
