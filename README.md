# k8s-proxysql-cluster
Container to run proxysql in cluster mode in kubernetes.

## Usage
By default te the container acts as a normal proxysql instance. 
To enable cluster mode the following is needed.

#### Service
the container uses a service to discover if there are already master nodes up.
This service can be found in
```
/k8s/proxysql.service.yaml
``` 
use the following command to use the service in kubernetes
```
kubectl create -f ./k8s/proxysql.service.yaml
``` 

#### Statefulset
To deploy the actual nodes a statefulset should be added to the kubernetes cluster
This statefulset can be found in
```
/k8s/proxysql.statefulset.yaml
``` 
use the following command to use the statefulset in kubernetes
```
kubectl create -f ./k8s/proxysql.statefulset.yaml
``` 

## Helm Install

You can install using the helm repository using the following command:

```bash
helm install --name db-proxy deploy/charts/proxysql-cluster 
```

| Parameter | Description | Default |
|----|-----------|-------------|
| `image.repository` | `proxysql` image repo | `scienta/k8s-proxysql-cluster` |
| `image.tag` | `proxysql` image tag | `1.0.0` |
| `numReplicas` | Number of replicas to create in StatefulSet | `3` |
| `proxysql.admin.username` | Admin username for `proxysql` | `admin` |
| `proxysql.admin.password` | Admin password for `proxysql` | `admin` |
| `proxysql.admin.iface` | Listen network for `proxysql` service | `0.0.0.0` |
| `proxysql.admin.port` | Listen port for `proxysql` service | `6032` |
| `proxysql.clusterAdmin.username` | Cluster user username used by `proxysql` nodes to sync | `cluster1` |
| `proxysql.clusterAdmin.password` | Cluster user password used by `proxysql` nodes to sync | `secret1pass` |
| `proxysql.queryCacheSizeMb` | (Optional) Query cache size | `nil` |
| `proxysql.dataDir` | Directory to store `proxysql` tables, etc. | `/var/lib/proxysql` |
| `proxysql.webEnabled` | Enable `proxysql` web dashboard | `true` |
| `mysql.iface` | Listen network for `mysql` service connections | `0.0.0.0` |
| `mysql.port` | Listen port fo `mysql` service connections | `3306` |
| `mysql.monitor.username` | Monitor username on MySQL instances for `proxysql` health checks | `monitor` |
| `mysql.monitor.password` | Monitor password on MySQL instances for `proxysql` health checks | `monitor` |
| `mysql.admin.username` | Root / admin username on MySQL instances | `root` |
| `mysql.admin.password` | Root / admin password on MySQL instances | `insecurepassword` |
| `cronjob.enabled` | Enable k8s `CronJob` to sync `proxysql` configurations | `false` |
| `resources` | CPU / Memory Limits and Requests | `{}` |
| `tolerations` | Pod tolerations | '{}' |

## Workings
When the container is run with the --k8s-cluster argument the following happens:
- the container checks if there is a node available at the proxysql service
- If no node is available this container becomes the first master node of the cluster
    - The node deletes the proxysql server from the proxysql_servers table
    - The node adds its own ip to its proxysql_servers table

- Else the node wil join the existing master nodes
    - The node's proxysql_servers table is synced with that of the existing master nodes
    - The node adds its own ip to the proxysql_servers table of the node exposed by the proxysql service.
    - The node deletes the proxysql service from the proxysql_servers table
    
- The cluster is up and running!
