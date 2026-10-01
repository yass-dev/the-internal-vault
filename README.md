# the-internal-vault

Internal automation library used by the vault platform workflows.

## Action

The root `action.yml` defines a composite action (pre/main/post). Reference it from any workflow in the same organization:

```yaml
- name: Run the-internal-vault
  uses: yass-dev/the-internal-vault@main
```

## Scripts

All scripts live in `scripts/` and are called from workflow steps.
