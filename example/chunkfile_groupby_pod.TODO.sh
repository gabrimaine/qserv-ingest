kubectl exec -it qserv-ingest-db-0 -- mysql -h localhost -u root -pCHANGEME -e 'select count(*), locking_pod, `database` from qservIngest.chunkfile_queue WHERE succeed is NULL and `database` LIKE '\''%'\''  GROUP BY locking_pod;