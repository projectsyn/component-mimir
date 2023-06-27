local com = import 'lib/commodore.libjsonnet';
local inv = com.inventory();
local params = inv.parameters.mimir;

local dir = std.extVar('output_path');
local override = params.nginx_resolver_override;

local fix = function(o)
  if override != '' && o.kind == 'ConfigMap' && o.metadata.name == 'mimir-nginx' && std.objectHas(o.data, 'nginx.conf') then
    o {
      data+: {
        'nginx.conf': std.lines(std.map(
          function(line)
            local elems = std.filter(function(e) e != '', std.split(line, ' '));
            if std.length(elems) >= 1 && elems[0] == 'resolver' then
              '  resolver %s;' % override
            else
              line,
          std.split(o.data['nginx.conf'], '\n'),
        )),
      },
    }
  else
    o;

// fixupDir already drops `null` objects, so we can just give the identity
// function as the 2nd argument.
com.fixupDir(dir, fix)
