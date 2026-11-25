# infra-events

Terraform dos **tópicos Pub/Sub** do FIAP X ([`fiap-x-vcosta`](https://github.com/fiap-x-vcosta)).

Canon de produto: [`docs`](https://github.com/fiap-x-vcosta/docs) — [catálogo de eventos](https://github.com/fiap-x-vcosta/docs/blob/main/eventos/catalogo-de-eventos.md).

## Escopo

- 3 tópicos Pub/Sub (um por tipo de evento do catálogo)
- Persistência de mensagem restrita a `us-central1`
- Output `topic_names`: mapa do id para o nome completo `projects/{project}/topics/{id}`
- Região `us-central1`, projeto `fiap-x-vcosta`
- State remoto em GCS (bucket gerenciado pelo [`infra-bootstrap`](https://github.com/fiap-x-vcosta/infra-bootstrap); `tf-destroy` não o apaga)

Quem publica recebe `roles/pubsub.publisher` no Terraform do **próprio serviço**. Subscription, `roles/pubsub.subscriber` e tópico de dead-letter nascem no Terraform do **serviço que consome**. Este stack **não** cria subscription nem binding de IAM.

Root module: [`terraform/`](terraform/). Pin Terraform: **1.16.1** (alinhado a [`actions`](https://github.com/fiap-x-vcosta/actions)).

## Tópicos

| Id | Publicador | Consumidores |
|----|------------|--------------|
| `upload-video-atualizado` | `upload-service` | `processamento-service` (worker), `notificacao-service` |
| `processamento-video-atualizado` | `processamento-service` (worker) | `upload-service`, `notificacao-service` |
| `cancelamento-solicitado` | `processamento-service` (api) | `processamento-service` (worker) |

Filtros de atributo (`etapa`, `resultado`, `status`) ficam na subscription de cada consumidor — ver arquivos em [`docs/eventos/`](https://github.com/fiap-x-vcosta/docs/tree/main/eventos).

`autenticacao-service`, `consultas-service` (`bff`) e `web` não publicam nem consomem estes tópicos. A SA de runtime de `processamento-service` é compartilhada por api e worker ([`infra-bootstrap`](https://github.com/fiap-x-vcosta/infra-bootstrap)).

## State (GCS)

| Item | Valor |
|------|--------|
| Bucket | `fiap-x-vcosta-tfstate` |
| Prefix deste repo | `infra-events` |

Este stack não lê o state de outro repositório. Não há org var para id de tópico — os serviços usam os ids literais do catálogo.

## CI vs CD

| Tipo | Quando | Automático? |
|------|--------|-------------|
| **CI** `fmt` + `validate` | PR / push | Sim |
| **CI** `plan` (OIDC) | PR | Sim |
| **`tf-apply` / `tf-destroy`** | Janela da demo / sob demanda | Só manual (`workflow_dispatch`) |

Merge em `main` **nunca** cria tópico. Callers `tf-apply` / `tf-destroy` entram em PR seguinte.

## Comandos locais

```bash
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

Plan/apply local exigem ADC (`gcloud auth application-default login`) e backend GCS (`terraform init` sem `-backend=false`).

## Roles da SA `github-actions` (least-privilege)

A service account, o OIDC e as roles são código no [`infra-bootstrap`](https://github.com/fiap-x-vcosta/infra-bootstrap). Deste conjunto, este stack usa:

- role customizada `ciPubSubAdmin` — criar, alterar e apagar tópicos
- no bucket de state: `roles/storage.objectAdmin`

Este repositório já está em `ci_repositories` do bootstrap (WIF por repositório).

## Ordem na demo

O `infra-bootstrap` já está aplicado e não entra neste ciclo. O destroy daqui não toca no bucket de state.

Subida:

1. `infra-k8s` → **tf-apply**, em paralelo com este repo → **tf-apply** (tópicos antes das subscriptions)
2. **tf-apply** de cada serviço (Cloud SQL + subscription/dead-letter + IAM)
3. Deploy dos serviços

Descida:

1. **tf-destroy** de cada serviço (subscriptions saem primeiro; tópico com subscription não apaga)
2. Este repo → **tf-destroy**
3. `infra-k8s` → **tf-destroy**

## Agentes

Ver [AGENTS.md](AGENTS.md).
