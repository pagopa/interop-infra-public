locals {
  platform_states_string_attributes = ["PK"]
  token_generation_states_string_attributes = [
    "PK",
    "GSIPK_consumerId_eserviceId",
    "GSIPK_eserviceId_descriptorId",
    "GSIPK_purposeId",
    "GSIPK_clientId",
    "GSIPK_clientId_kid",
    "GSIPK_clientId_purposeId"
  ]
}

resource "aws_dynamodb_table" "platform_states" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%s-platform-states-%s", local.project, var.env)

  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true

  hash_key = "PK"

  dynamic "attribute" {
    for_each = toset(local.platform_states_string_attributes)

    content {
      name = attribute.key
      type = "S"
    }
  }
}

resource "aws_dynamodb_table" "token_generation_states" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%s-token-generation-states-%s", local.project, var.env)

  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true

  hash_key = "PK"

  dynamic "attribute" {
    for_each = toset(local.token_generation_states_string_attributes)

    content {
      name = attribute.key
      type = "S"
    }
  }

  global_secondary_index {
    name = "Agreement"

    hash_key        = "GSIPK_consumerId_eserviceId"
    projection_type = "INCLUDE"
    non_key_attributes = [
      "agreementState",
      "descriptorState",
      "descriptorAudience",
      "descriptorVoucherLifespan"
    ] # implicit include: table and GSI HK, SK
  }

  global_secondary_index {
    name = "Descriptor"

    hash_key        = "GSIPK_eserviceId_descriptorId"
    projection_type = "KEYS_ONLY" # implicit include: table and GSI HK, SK
  }

  global_secondary_index {
    name = "Purpose"

    hash_key        = "GSIPK_purposeId"
    projection_type = "INCLUDE"
    non_key_attributes = [
      "agreementId",
      "agreementState",
      "GSIPK_eserviceId_descriptorId",
      "descriptorAudience",
      "descriptorState",
      "descriptorVoucherLifespan",
      "purposeState",
      "purposeVersionId",
      "producerId"
    ] # implicit include: table and GSI HK, SK
  }

  global_secondary_index {
    name = "Client"

    hash_key        = "GSIPK_clientId"
    projection_type = "INCLUDE"
    non_key_attributes = [
      "consumerId",
      "clientKind",
      "GSIPK_clientId_kid",
      "publicKey"
    ] # implicit include: table and GSI HK, SK
  }

  global_secondary_index {
    name = "ClientKid"

    hash_key        = "GSIPK_clientId_kid"
    projection_type = "KEYS_ONLY" # implicit include: table and GSI HK, SK
  }

  global_secondary_index {
    name = "ClientPurpose"

    hash_key        = "GSIPK_clientId_purposeId"
    projection_type = "INCLUDE"
    non_key_attributes = [
      "GSIPK_clientId",
      "GSIPK_clientId_kid",
      "GSIPK_purposeId",
      "consumerId",
      "clientKind",
      "publicKey"
    ] # implicit include: table and GSI HK, SK
  }
}

resource "aws_dynamodb_table" "dpop_cache" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%s-dpop-cache-%s", local.project, var.env)

  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = true

  hash_key = "jti"

  attribute {
    name = "jti"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}
