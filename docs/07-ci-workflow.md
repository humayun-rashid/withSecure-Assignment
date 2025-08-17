
---

## 📘 `docs/07-ci-workflow.md`

```markdown
# 7. CI Workflow

GitHub Actions runs Terraform for `ci/` environment.

## Triggers
- Pull requests → `terraform plan`.
- Push to `main` → `terraform apply`.
- Manual dispatch → plan/apply/destroy.

## Steps
1. Checkout code.
2. Setup Terraform.
3. Assume AWS OIDC role.
4. Terraform init (remote backend).
5. Validate → Plan → Apply.
6. Smoke test: call `http://ALB/health`.

## Destroy
Run manual workflow dispatch with `action=destroy`.
