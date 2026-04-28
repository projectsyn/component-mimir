local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.mimir;
local isOpenshift = std.member([ 'openshift4', 'oke' ], inv.parameters.facts.distribution);

local s3endpoint =
  if params.s3.endpoint != null then
    params.s3.endpoint
  else if std.get(inv.parameters.facts, 'cloud') == 'cloudscale' then
    'objects.%s.cloudscale.ch' % std.stripChars(std.get(inv.parameters.facts, 'region', 'lpg'), '0123456789')
  else if std.get(inv.parameters.facts, 'cloud') == 'exoscale' then
    'sos-%s.exo.io' % std.get(inv.parameters.facts, 'region', 'ch-gva-2')
  else
    '${S3_ENDPOINT}';

// Global Params and Zone Aware Replication
local globalConfig = params.global + com.makeMergeable({
  nodeSelector: std.get(params, 'globalNodeSelector', params.global.nodeSelector),
  zoneAwareReplication: params.global.zoneAwareReplication,
});

local components = com.makeMergeable({
  // // Read Path
  querier: {
    nodeSelector: std.get(params.components.querier, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.querier),
  query_frontend: {
    nodeSelector: std.get(params.components.queryFrontend, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.queryFrontend),
  query_scheduler: {
    nodeSelector: std.get(params.components.queryScheduler, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.queryScheduler),
  store_gateway: {
    nodeSelector: std.get(params.components.storeGateway, 'nodeSelector', globalConfig.nodeSelector),
    zoneAwareReplication: globalConfig.zoneAwareReplication,  // 👈 TODO: think about that
  } + com.makeMergeable(params.components.storeGateway),
  // // Write Path
  distributor: {
    nodeSelector: std.get(params.components.distributor, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.distributor),
  ingester: {
    nodeSelector: std.get(params.components.ingester, 'nodeSelector', globalConfig.nodeSelector),
    zoneAwareReplication: globalConfig.zoneAwareReplication,  // 👈 TODO: think about that
  } + com.makeMergeable(params.components.ingester),
  // Backend
  compactor: {
    nodeSelector: std.get(params.components.compactor, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.compactor),
  rollout_operator: {
    nodeSelector: std.get(params.components.rolloutOperator, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.rolloutOperator),
  // Ingress Configuration
  gateway: {
    nodeSelector: std.get(params.components.gateway, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.gateway),
  nginx: {
    nodeSelector: std.get(params.components.nginx, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.nginx),
  // "Optional" components
  alertmanager: {
    nodeSelector: std.get(params.components.alertmanager, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.alertmanager),
  overrides_exporter: {
    nodeSelector: std.get(params.components.overridesExporter, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.overridesExporter),
  ruler: {
    nodeSelector: std.get(params.components.ruler, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.components.ruler),
});

// Caches
local caches = com.makeMergeable({
  'chunks-cache': {
    nodeSelector: std.get(params.caches.chunks, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.caches.chunks),
  'index-cache': {
    nodeSelector: std.get(params.caches.index, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.caches.index),
  'metadata-cache': {
    nodeSelector: std.get(params.caches.metadata, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.caches.metadata),
  'results-cache': {
    nodeSelector: std.get(params.caches.results, 'nodeSelector', globalConfig.nodeSelector),
  } + com.makeMergeable(params.caches.results),
});

// Global Config
local openshift = if isOpenshift then com.makeMergeable({
  global: {
    dnsService: 'dns-default',
    dnsNamespace: 'openshift-dns',
  },
  rbac: {
    type: 'scc',
    podSecurityContext: {
      fsGroup: null,
      runAsGroup: null,
      runAsUser: null,
    },
  },
  rollout_operator: {
    podSecurityContext: {
      fsGroup: null,
      runAsGroup: null,
      runAsUser: null,
    },
  },
}) else {};

local images = com.makeMergeable({
  image: {
    repository: '%(registry)s/%(repository)s' % params.images.mimir,
    tag: params.images.mimir.tag,
  },
  memcached: {
    image: {
      repository: '%(registry)s/%(repository)s' % params.images.memcached,
      tag: params.images.memcached.tag,
    },
  },
  memcachedExporter: {
    image: {
      repository: '%(registry)s/%(repository)s' % params.images.memcachedExporter,
      tag: params.images.memcachedExporter.tag,
    },
  },
  nginx: {
    image: {
      registry: params.images.nginx.registry,
      repository: params.images.nginx.repository,
      tag: params.images.nginx.tag,
    },
  },
  gateway: {
    nginx: {
      image: {
        registry: params.images.nginx.registry,
        repository: params.images.nginx.repository,
        tag: params.images.nginx.tag,
      },
    },
  },
  rollout_operator: {
    image: {
      repository: '%(registry)s/%(repository)s' % params.images.rolloutOperator,
      tag: params.images.rolloutOperator.tag,
    },
  },
});

local global = com.makeMergeable({
  //   global: {
  //     extraEnvFrom: [ {
  //       secretRef: {
  //         name: 'mimir-bucket-secret',
  //       },
  //     } ],
  //     podAnnotations: {
  //       bucketSecretVersion: '%s' % params.s3.auth.secretVersion,
  //     },
  //   },
  minio: {
    enabled: false,
  },
  //   [if params.monitoring then 'metaMonitoring']: {
  //     serviceMonitor: {
  //       enabled: params.monitoring,
  //     },
  //     prometheusRule: {
  //       enabled: params.monitoring,
  //       mimirAlerts: true,
  //       mimirRules: true,
  //     },
  //   },
});

// Mimir Config
local mimir = com.makeMergeable({
//   mimir: {
//     structuredConfig: {
//       alertmanager_storage: {
//         backend: 's3',
//         s3: {
//           bucket_name: '%s-alertmanager-bucket' % params.s3.bucketPrefix,
//           endpoint: s3endpoint,
//           [if params.s3.region != null then 'region']: params.s3.region,
//           [if params.s3.insecure then 'insecure']: true,
//           access_key_id: '${S3_ACCESS_KEY_ID}',
//           secret_access_key: '${S3_SECRET_ACCESS_KEY}',
//         },
//       },
//       blocks_storage: {
//         backend: 's3',
//         s3: {
//           bucket_name: '%s-blocks-bucket' % params.s3.bucketPrefix,
//           endpoint: s3endpoint,
//           [if params.s3.region != null then 'region']: params.s3.region,
//           [if params.s3.insecure then 'insecure']: true,
//           access_key_id: '${S3_ACCESS_KEY_ID}',
//           secret_access_key: '${S3_SECRET_ACCESS_KEY}',
//         },
//       },
//       ruler_storage: {
//         backend: 's3',
//         s3: {
//           bucket_name: '%s-ruler-bucket' % params.s3.bucketPrefix,
//           endpoint: s3endpoint,
//           [if params.s3.region != null then 'region']: params.s3.region,
//           [if params.s3.insecure then 'insecure']: true,
//           access_key_id: '${S3_ACCESS_KEY_ID}',
//           secret_access_key: '${S3_SECRET_ACCESS_KEY}',
//         },
//       },
//       [if params.config.tenantFederation then 'tenant_federation']: {
//         enabled: params.config.tenantFederation,
//       },
//       [if params.config.tenantFederation then 'ruler']: {
//         tenant_federation: {
//           enabled: params.config.tenantFederation,
//         },
//       },
//       [if params.config.haTracker then 'limits']: {
//         accept_ha_samples: true,
//         ha_cluster_label: params.config.haLabels.cluster,
//         ha_replica_label: params.config.haLabels.replica,
//       },
//       [if params.config.haTracker then 'distributor']: {
//         ha_tracker: {
//           enable_ha_tracker: true,
//           ha_tracker_failover_timeout: '60s',
//           kvstore: {
//             // prefix: '%s/' % inv.parameters._instance,  // 👈 TODO: think about that
//             store: params.config.haStore.type,
//             [params.config.haStore.type]: {
//               [obj]: params.config.haStore[obj]
//               for obj in std.objectFields(params.config.haStore)
//               if obj != 'type'
//             },
//           },
//         },
//       },
//     },
//   },
});

{
  ['%s-components' % inv.parameters._instance]: components + caches,
    ['%s-configs' % inv.parameters._instance]: openshift + images + global + mimir,
  ['%s-overrides' % inv.parameters._instance]: params.helm_values,
}
