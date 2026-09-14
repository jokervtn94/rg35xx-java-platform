#!/usr/bin/env python3
from pathlib import Path
import sys
p = Path(sys.argv[1] if len(sys.argv) > 1 else 'upstream-miyoo') / 'src/org/recompile/mobile/MIDletLoader.java'
s = p.read_text(encoding='utf-8')
patterns = [
 ('import_Path', 'import java.nio.file.Path;\n'),
 ('import_Paths', 'import java.nio.file.Paths;\n'),
 ('import_Files', 'import java.nio.file.Files;\n'),
 ('import_FileSystem', 'import java.nio.file.FileSystem;\n'),
 ('import_FileSystems', 'import java.nio.file.FileSystems;\n'),
 ('import_StandardOpenOption', 'import java.nio.file.StandardOpenOption;\n'),
 ('import_DirectoryStream', 'import java.nio.file.DirectoryStream;\n'),
 ('import_StandardCopyOption', 'import java.nio.file.StandardCopyOption;\n'),
 ('import_URI', 'import java.net.URI;\n'),
 ('field_zipfs', '\tFileSystem zipfs;'),
 ('loadManifest_Path_decl', '\t\tPath url = findJarResource(resource);'),
 ('manifest_newInputStream', 'InputStream is = Files.newInputStream(url,StandardOpenOption.READ);'),
 ('resource_Path_decl', '\t\tPath url;'),
 ('resource_newInputStream', 'InputStream stream = Files.newInputStream(url,StandardOpenOption.READ);'),
 ('stream_copy_return', '\t\t\twhile (count!=-1)\n\t\t\t{\n\t\t\t\tcount = stream.read(data);\n\t\t\t\tif(count!=-1) { buffer.write(data, 0, count); }\n\t\t\t}\n\t\t\treturn new ByteArrayInputStream(buffer.toByteArray());'),
]
print('M1.4C2A MIDLET REPLACEMENT COUNTS')
for name, pat in patterns:
    print('%s=%d' % (name, s.count(pat)))
print('new_Vector_diamond=%d' % s.count('new Vector<>()'))
print('new_HashMap_diamond=%d' % s.count('new HashMap<>()'))
print('Path_token_count=%d' % s.count('Path'))
