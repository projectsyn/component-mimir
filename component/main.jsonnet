// main template for mimir
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';

local prom = import 'lib/prom.libsonnet';

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
  // Empty file to make sure the directory is created. Later used in patching alerts.
  '10_mimir_distributed/mimir-distributed/templates/metamonitoring/.keep': {},

  '20_prometheus_rule': prom.generateRules('mimir-custom', { 'mimir-custom.rules': params.alerts.additionalRules }) {
    metadata+: {
      namespace: params.namespace.name,
    },
  },
}
