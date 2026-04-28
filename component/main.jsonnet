// main template for mimir
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.mimir;

local secrets = com.generateResources(
  {
    [if params.ingress.tls.enabled && params.ingress.tls.key != null && params.ingress.tls.cert != null then '%s-tls' % std.strReplace(params.ingress.url, '.', '-')]:
      {
        stringData: {
          'tls.key': params.ingress.tls.key,
          'tls.cert': params.ingress.tls.cert,
        },
      },
    [if params.basicAuth.enabled && params.basicAuth.htpasswd != null then '%s-nginx-htpasswd' % inv.parameters._instance]:
      {
        stringData: {
          '.htpasswd': params.basicAuth.htpasswd,
        },
      },
    'mimir-bucket-secret': {
      stringData: {
        S3_ACCESS_KEY_ID: params.s3.auth.accessKeyId,
        S3_SECRET_ACCESS_KEY: params.s3.auth.secretAccessKey,
      },
    },
  } + com.makeMergeable(params.secrets),
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
