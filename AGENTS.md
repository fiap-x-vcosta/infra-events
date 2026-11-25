# Guia para agentes — `infra-events` (FIAP X)

Terraform dos **tópicos Pub/Sub** do ciclo de demo do FIAP X. Org [`fiap-x-vcosta`](https://github.com/fiap-x-vcosta).

Canon de produto (catálogo): [`docs`](https://github.com/fiap-x-vcosta/docs) → `eventos/`.

## Antes de mudar código

1. Ler o [README](README.md) e o [catálogo de eventos](https://github.com/fiap-x-vcosta/docs/blob/main/eventos/catalogo-de-eventos.md)
2. Espelhar o layout flat em `terraform/`; não inventar layout paralelo
3. Não rodar `apply`/`destroy` sem confirmação explícita do usuário
4. **Git:** nunca commit/push direto em `main` — branch → PR → merge humano (ver [`.cursor/rules/git-workflow.mdc`](.cursor/rules/git-workflow.mdc))
5. Naming: proibida a string que combina o produto com “videos” em camel/kebab/snake

## Responsabilidade

| Peça | Papel |
|------|--------|
| Terraform | Tópicos Pub/Sub do catálogo + output `topic_names` |
| Apply/destroy | Manuais via callers `tf-apply` / `tf-destroy` (`workflow_dispatch`) |
| Fora de escopo | Subscriptions, DLQ, IAM publisher/subscriber, Cloud SQL, GKE, código dos serviços |

## Regras canônicas (resumo)

- Um tópico por tipo de evento do catálogo
- Subscriptions e IAM moram no Terraform de cada serviço
- CI barato (`fmt` / `validate` / `plan`); CD caro só manual
- Sem secrets no Git; README autocontido na org

## Comandos

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
# plan/apply reais: só com backend GCS e confirmação humana (workflow ou ADC)
```
