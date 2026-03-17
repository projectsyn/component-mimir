local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.mimir;
local isOpenshift = std.member([ 'openshift4', 'oke' ], inv.parameters.facts.distribution);

// Global Params and Zone Aware Replication
local globalConfig = {
  nodeSelector: params.globalNodeSelector,
};

local zoneAwareReplication = globalConfig.zoneAwareReplication {
  [if std.length(globalConfig.zoneAwareReplication.zones) == 0 then 'zones']: [
    { name: 'zone-a', nodeSelector: { 'topology.kubernetes.io/zone': 'zone-a' } },
    { name: 'zone-b', nodeSelector: { 'topology.kubernetes.io/zone': 'zone-b' } },
    { name: 'zone-c', nodeSelector: { 'topology.kubernetes.io/zone': 'zone-c' } },
  ],
};

local components = com.makeMergeable({
  // // Read Path
  querier: {
    nodeSelector: std.get(params.components.querier, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.querier),
  query_frontend: {
    nodeSelector: std.get(params.components.queryFrontend, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.queryFrontend),
  query_scheduler: {
    nodeSelector: std.get(params.components.queryScheduler, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.queryScheduler),
  store_gateway: {
    nodeSelector: std.get(params.components.storeGateway, 'nodeSelector', params.globalNodeSelector),
    // zoneAwareReplication: zoneAwareReplication,  // 👈 TODO: think about that
  } + com.makeMergeable(params.components.storeGateway),
  // // Write Path
  distributor: {
    nodeSelector: std.get(params.components.distributor, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.distributor),
  ingester: {
    nodeSelector: std.get(params.components.ingester, 'nodeSelector', params.globalNodeSelector),
    // zoneAwareReplication: zoneAwareReplication,  // 👈 TODO: think about that
  } + com.makeMergeable(params.components.ingester),
  // Backend
  compactor: {
    nodeSelector: std.get(params.components.compactor, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.compactor),
  rollout_operator: {
    nodeSelector: std.get(params.components.rolloutOperator, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.rolloutOperator),
  // Ingress Configuration
  gateway: {
    nodeSelector: std.get(params.components.gateway, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.gateway),
  nginx: {
    nodeSelector: std.get(params.components.nginx, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.nginx),
  // "Optional" components
  alertmanager: {
    nodeSelector: std.get(params.components.alertmanager, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.alertmanager),
  overrides_exporter: {
    nodeSelector: std.get(params.components.overridesExporter, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.overridesExporter),
  ruler: {
    nodeSelector: std.get(params.components.ruler, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.components.ruler),
});

// Caches
local caches = com.makeMergeable({
  'chunks-cache': {
    nodeSelector: std.get(params.caches.chunks, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.caches.chunks),
  'index-cache': {
    nodeSelector: std.get(params.caches.index, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.caches.index),
  'metadata-cache': {
    nodeSelector: std.get(params.caches.metadata, 'nodeSelector', params.globalNodeSelector),
  } + com.makeMergeable(params.caches.metadata),
  'results-cache': {
    nodeSelector: std.get(params.caches.results, 'nodeSelector', params.globalNodeSelector),
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

local global = com.makeMergeable({
  minio: {
    enabled: false,
  },
});

{
  ['%s-components' % inv.parameters._instance]: components + caches,
  ['%s-configs' % inv.parameters._instance]: openshift + global,
  ['%s-overrides' % inv.parameters._instance]: params.helm_values,
}
