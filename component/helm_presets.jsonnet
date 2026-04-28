local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.mimir;

// Prevent selecting a non-existent preset
assert std.member([ 'none', 'extra-small', 'small', 'large' ], params.preset) : 'params.preset must be one of: none, extra-small, small, large';

{
  none: {},
  // Extrasmall preset
  'extra-small': {
    alertmanager: {
      replicas: 3,
      resources: {
        limits: {
          memory: '512Mi',
        },
        requests: {
          cpu: '250m',
          memory: '256Mi',
        },
      },
    },
    compactor: {
      replicas: 1,
      resources: {
        limits: {
          memory: '512Mi',
        },
        requests: {
          cpu: '250m',
          memory: '384Mi',
        },
      },
    },
    distributor: {
      replicas: 3,
      resources: {
        limits: {
          memory: '4Gi',
        },
        requests: {
          cpu: '500m',
          memory: '2Gi',
        },
      },
    },
    gateway: {
      replicas: 3,
      resources: {
        limits: {
          memory: '731Mi',
        },
        requests: {
          cpu: 1,
          memory: '512Mi',
        },
      },
    },
    ingester: {
      replicas: 4,
      resources: {
        limits: {
          memory: '16Gi',
        },
        requests: {
          cpu: 1,
          memory: '8Gi',
        },
      },
    },
    overrides_exporter: {
      replicas: 1,
      resources: {
        limits: {
          memory: '128Mi',
        },
        requests: {
          cpu: '100m',
          memory: '128Mi',
        },
      },
    },
    querier: {
      replicas: 2,
      resources: {
        limits: {
          memory: '4Gi',
        },
        requests: {
          cpu: 1,
          memory: '2Gi',
        },
      },
    },
    query_frontend: {
      replicas: 1,
      resources: {
        limits: {
          memory: '2Gi',
        },
        requests: {
          cpu: 1,
          memory: '1Gi',
        },
      },
    },
    query_scheduler: {
      replicas: 2,
    },
    ruler: {
      replicas: 2,
      resources: {
        limits: {
          memory: '768Mi',
        },
        requests: {
          cpu: '250m',
          memory: '512Mi',
        },
      },
    },
    store_gateway: {
      replicas: 1,
      resources: {
        limits: {
          memory: '2.1Gi',
        },
        requests: {
          cpu: '500m',
          memory: '768Mi',
        },
      },
      persistentVolume: {
        size: '30Gi',
      },
    },
    'chunks-cache': {
      replicas: 2,
      resources: {
        limits: {
          memory: '4Gi',
        },
        requests: {
          cpu: '500m',
          memory: '4Gi',
        },
      },
    },
    'index-cache': {
      replicas: 3,
      resources: {
        limits: {
          memory: '1500Mi',
        },
        requests: {
          cpu: '500m',
          memory: '1500Mi',
        },
      },
    },
    'metadata-cache': {
      replicas: 1,
      resources: {
        limits: {
          memory: '614Mi',
        },
        requests: {
          cpu: '500m',
          memory: '614Mi',
        },
      },
    },
    'results-cache': {
      replicas: 2,
      resources: {
        limits: {
          memory: '614Mi',
        },
        requests: {
          cpu: '500m',
          memory: '614Mi',
        },
      },
    },
  },
}
