# 8. Cleanup

Sometimes `terraform destroy` fails (due to ordering or dangling resources).  
Use `cleanup-ci.sh`:

- Deletes ECS services, clusters, task defs.
- Deletes ALBs, target groups.
- Cleans up SGs, ENIs.
- Removes VPC, subnets, route tables, IGWs.

⚠️ Use only for CI — **not for prod/staging**!
