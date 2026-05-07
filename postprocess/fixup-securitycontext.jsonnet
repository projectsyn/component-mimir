local com = import 'lib/commodore.libjsonnet';
local inv = com.inventory();
local params = inv.parameters.mimir;
local isOpenshift = std.member([ 'openshift4', 'oke' ], inv.parameters.facts.distribution);

local dir = std.extVar('output_path');

if isOpenshift && params.components.rolloutOperator.enabled then com.fixupDir(dir, std.prune) else {}
