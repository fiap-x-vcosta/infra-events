locals {
  topic_ids = toset([
    "upload-video-atualizado",
    "processamento-video-atualizado",
    "cancelamento-solicitado",
  ])
}

resource "google_pubsub_topic" "catalog" {
  for_each = local.topic_ids
  name     = each.value

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }
}
