// main template for mimir
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';

// The hiera parameters for the component
local params = inv.parameters.mimir;

local secrets = com.generateResources(
  params.secrets,
  function(name) kube.Secret(name) {
    metadata+: {
      namespace: params.namespace.name,
    },
  }
);


// Define outputs below
{
  [if params.namespace.create then '00_namespace']: kube.Namespace(params.namespace.name) {
    metadata+: com.makeMergeable(params.namespace.metadata),
  },
  '01_secrets': secrets,
}
