local com = import 'lib/commodore.libjsonnet';

local dir = std.extVar('output_path');

com.fixupDir(dir, std.prune)
