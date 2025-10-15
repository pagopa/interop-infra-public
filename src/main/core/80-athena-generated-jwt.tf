resource "aws_athena_named_query" "create_generated_jwt_table" {
  name      = "create-generated-jwt-table"
  workgroup = aws_athena_workgroup.interop_queries.id
  database  = "default"

  query = <<-EOT
    CREATE EXTERNAL TABLE generated_jwt_${var.env} (
    agreementId string,
    algorithm string,
    audience string,
    clientAssertion struct<
      algorithm: string,
      audience: string,
      expirationTime: bigint,
      issuedAt: bigint,
      issuer: string,
      jwtId: string,
      keyId: string,
      subject: string
    >,
    clientId string,
    descriptorId string,
    eserviceId string,
    expirationTime bigint,
    issuedAt bigint,
    issuer string,
    jwtId string,
    keyId string,
    notBefore bigint,
    organizationId string,
    purposeId string,
    purposeVersionId string,
    subject string
  )
  PARTITIONED BY
  (
    day STRING
  )
  ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
  WITH SERDEPROPERTIES ('ignore.malformed.json' = 'false')
  LOCATION 's3://interop-generated-jwt-details-${var.env}-es1/token-details/'
  TBLPROPERTIES
  (
    "projection.enabled" = "true",
    "projection.day.type" = "date",
    "projection.day.range" = "20220101,NOW",
    "projection.day.format" = "yyyyMMdd",
    "projection.day.interval" = "1",
    "projection.day.interval.unit" = "DAYS",
    "storage.location.template" = "s3://interop-generated-jwt-details-${var.env}-es1/token-details/$${day}"
  )
  EOT
}
