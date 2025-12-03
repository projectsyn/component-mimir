local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.mimir;

// Zone Aware Replication
local zoneAwareReplication = {
  enabled: params.config.zoneAwareReplication,
  zones: [
    { name: 'zone-a', nodeSelector: params.config.nodeSelector },
    { name: 'zone-b', nodeSelector: params.config.nodeSelector },
    { name: 'zone-c', nodeSelector: params.config.nodeSelector },
  ],
};

// Topology Spread Constaints
local topologySpreadConstraints = {
  maxSkew: 1,
  topologyKey: 'kubernetes.io/hostname',
  whenUnsatisfiable: 'ScheduleAnyway',
};

local components = com.makeMergeable({
  // Read Path
  querier: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.querier.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.components.querier),
  query_frontend: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.queryFrontend.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.components.queryFrontend),
  store_gateway: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.storeGateway.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.config.storageClass,
    },
    zoneAwareReplication: zoneAwareReplication,
  } + com.makeMergeable(params.components.storeGateway),
  // Write Path
  distributor: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.distributor.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.components.distributor),
  ingester: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.ingester.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.config.storageClass,
    },
    zoneAwareReplication: zoneAwareReplication,
  } + com.makeMergeable(params.components.ingester),
  // Backend
  compactor: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.compactor.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.config.storageClass,
    },
  } + com.makeMergeable(params.components.compactor),
  overrides_exporter: {
    nodeSelector: params.config.nodeSelector,
  } + com.makeMergeable(params.components.overridesExporter),
  // Ingress Configuration
  gateway: {
    // enabledNonEnterprise: true,
    nodeSelector: params.config.nodeSelector,
    [if params.components.gateway.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  },
  // "Optional" components
  alertmanager: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.alertmanager.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.config.storageClass,
    },
  } + com.makeMergeable(params.components.alertmanager),
  query_scheduler: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.queryScheduler.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.components.queryScheduler),
  ruler: {
    nodeSelector: params.config.nodeSelector,
    [if params.components.ruler.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.components.ruler),
  rollout_operator: {
    nodeSelector: params.config.nodeSelector,
  } + com.makeMergeable(params.components.rolloutOperator),
  // Ingress components
  nginx: {
    nodeSelector: params.config.nodeSelector,
  },
});

// Caches
local caches = com.makeMergeable({
  'chunks-cache': {
    nodeSelector: params.config.nodeSelector,
    [if params.caches.chunks.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.caches.chunks),
  'index-cache': {
    nodeSelector: params.config.nodeSelector,
    [if params.caches.index.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.caches.index),
  'metadata-cache': {
    nodeSelector: params.config.nodeSelector,
    [if params.caches.metadata.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.caches.metadata),
  'results-cache': {
    nodeSelector: params.config.nodeSelector,
    [if params.caches.results.replicas > 1 then 'topologySpreadConstraints']: topologySpreadConstraints,
  } + com.makeMergeable(params.caches.results),
});

// Global Config
local global = {
  global: {
    extraEnvFrom: [ {
      secretRef: {
        name: 'mimir-bucket-secret',
      },
    } ],
    podAnnotations: {
      // increase if bucket secrets change
      bucketSecretVersion: '0',
    },
  },
};

// Mimir Config
local mimir = {
  mimir: {
    structuredConfig: {
      alertmanager_storage: {
        backend: 's3',
        s3: {
          bucket_name: '%s-alertmanager-bucket' % params.s3.bucketPrefix,
          endpoint: '${S3_ENDPOINT}',
          // region: params.s3.region,
          // insecure: params.s3.insecure,
          access_key_id: '${S3_ACCESS_KEY_ID}',
          secret_access_key: '${S3_SECRET_ACCESS_KEY}',
        },
      },
      blocks_storage: {
        backend: 's3',
        s3: {
          bucket_name: '%s-blocks-bucket' % params.s3.bucketPrefix,
          endpoint: '${S3_ENDPOINT}',
          // region: params.s3.region,
          // insecure: params.s3.insecure,
          access_key_id: '${S3_ACCESS_KEY_ID}',
          secret_access_key: '${S3_SECRET_ACCESS_KEY}',
        },
      },
      ruler_storage: {
        backend: 's3',
        s3: {
          bucket_name: '%s-ruler-bucket' % params.s3.bucketPrefix,
          endpoint: '${S3_ENDPOINT}',
          // region: params.s3.region,
          // insecure: params.s3.insecure,
          access_key_id: '${S3_ACCESS_KEY_ID}',
          secret_access_key: '${S3_SECRET_ACCESS_KEY}',
        },
      },
    },
  },
};

{
  ['%s-components' % inv.parameters._instance]: components + caches,
  ['%s-configs' % inv.parameters._instance]: global + mimir,
  ['%s-overrides' % inv.parameters._instance]: params.helm_values,
}
