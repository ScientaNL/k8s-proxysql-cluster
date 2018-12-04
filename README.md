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
