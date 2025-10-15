# AWS Glue Compatible Version: PySpark ETL for NDJSON to CSV Conversion

import sys
import os
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import DataFrame, SparkSession, Column
from pyspark.sql.functions import col, isnull, date_format, when
from pyspark.sql.types import StructType, StructField, StringType, LongType

# target file size for the output CSVs
TARGET_FILE_SIZE_MB = 100

# average size of a single JSON line in source files
ESTIMATED_BYTES_PER_JSON_RECORD = 1100

#  average size of a single row in the final CSV format
ESTIMATED_GENERATED_TOKEN_ROW_BYTES = 750
ESTIMATED_CLIENT_ASSERTION_ROW_BYTES = 350

def get_total_input_size_bytes(spark: SparkSession, path: str, logger) -> int:
    """
    Gets the total size of all files in a given S3 path using the Hadoop FileSystem API.
    This version uses globStatus to correctly handle wildcard paths.
    """
    logger.info(f"--> Calculating total input size for path: {path}...")
    try:
        uri = sc._jvm.java.net.URI(path)
        fs = sc._jvm.org.apache.hadoop.fs.FileSystem.get(uri, sc._jsc.hadoopConfiguration())
        path_pattern = sc._jvm.org.apache.hadoop.fs.Path(path)

        # Use globStatus to expand wildcards, then get the size of each matched file.
        total_size = 0
        for status in fs.globStatus(path_pattern):
            if status.isDirectory():
                # If the glob matches a directory, list its contents recursively
                content_iterator = fs.listFiles(status.getPath(), True)
                while content_iterator.hasNext():
                    total_size += content_iterator.next().getLen()
            else:
                total_size += status.getLen()

        logger.info(f"--> Found total input size: {round(total_size / (1024**2), 2)} MB.")
        return total_size
    except Exception as e:
        logger.error(f"--> Failed to calculate input size for path {path}. Error: {e}")
        return 0

def get_data_schema() -> StructType:
    client_assertion_schema = StructType([
        StructField("algorithm", StringType(), False),
        StructField("audience", StringType(), False),
        StructField("expirationTime", LongType(), False),
        StructField("issuedAt", LongType(), False),
        StructField("issuer", StringType(), False),
        StructField("jwtId", StringType(), False),
        StructField("keyId", StringType(), False),
        StructField("subject", StringType(), False)
    ])

    return StructType([
        StructField("agreementId", StringType(), False),
        StructField("algorithm", StringType(), False),
        StructField("audience", StringType(), False),
        StructField("clientAssertion", client_assertion_schema, False),
        StructField("clientId", StringType(), False),
        StructField("correlationId", StringType(), True), # Only nullable field
        StructField("descriptorId", StringType(), False),
        StructField("eserviceId", StringType(), False),
        StructField("expirationTime", LongType(), False),
        StructField("issuedAt", LongType(), False),
        StructField("issuer", StringType(), False),
        StructField("jwtId", StringType(), False),
        StructField("keyId", StringType(), False),
        StructField("notBefore", LongType(), False),
        StructField("organizationId", StringType(), False),
        StructField("purposeId", StringType(), False),
        StructField("purposeVersionId", StringType(), False),
        StructField("subject", StringType(), False)
    ])

def get_normalized_timestamp_col(timestamp_col: Column) -> Column:
    MICROSECOND_THRESHOLD = 100000000000000  # 10^14

    normalized_seconds = when(
        timestamp_col >= MICROSECOND_THRESHOLD,
        timestamp_col / 1000000
    ).otherwise(
        timestamp_col / 1000
    )

    return normalized_seconds.cast("timestamp")

def create_generated_token_df(df: DataFrame) -> DataFrame:
    return df.select(
        col("jwtId").alias("jwt_id"),
        col("correlationId").alias("correlation_id"),
        col("issuedAt").alias("issued_at"),
        date_format(get_normalized_timestamp_col(col("issuedAt")), "yyyy-MM-dd'T'HH:mm:ss'Z'").alias("issued_at_tz"),
        col("clientId").alias("client_id"),
        col("organizationId").alias("organization_id"),
        col("agreementId").alias("agreement_id"),
        col("eserviceId").alias("eservice_id"),
        col("descriptorId").alias("descriptor_id"),
        col("purposeId").alias("purpose_id"),
        col("purposeVersionId").alias("purpose_version_id"),
        col("algorithm"),
        col("keyId").alias("key_id"),
        col("audience"),
        col("subject"),
        col("notBefore").alias("not_before"),
        date_format(get_normalized_timestamp_col(col("notBefore")), "yyyy-MM-dd'T'HH:mm:ss'Z'").alias("not_before_tz"),
        col("expirationTime").alias("expiration_time"),
        date_format(get_normalized_timestamp_col(col("expirationTime")), "yyyy-MM-dd'T'HH:mm:ss'Z'").alias("expiration_time_tz"),
        col("issuer"),
        col("clientAssertion.jwtId").alias("client_assertion_jwt_id")
    )

def create_client_assertion_df(df: DataFrame) -> DataFrame:
    return df.select(
        col("clientAssertion.jwtId").alias("jwt_id"),
        col("clientAssertion.issuedAt").alias("issued_at"),
        date_format(get_normalized_timestamp_col(col("clientAssertion.issuedAt")), "yyyy-MM-dd'T'HH:mm:ss'Z'").alias("issued_at_tz"),
        col("clientAssertion.algorithm").alias("algorithm"),
        col("clientAssertion.keyId").alias("key_id"),
        col("clientAssertion.issuer").alias("issuer"),
        col("clientAssertion.subject").alias("subject"),
        col("clientAssertion.audience").alias("audience"),
        col("clientAssertion.expirationTime").alias("expiration_time"),
        date_format(get_normalized_timestamp_col(col("clientAssertion.expirationTime")), "yyyy-MM-dd'T'HH:mm:ss'Z'").alias("expiration_time_tz"),
        col("jwtId").alias("generated_token_jwt_id")
    )

def write_df_to_csv(logger, df: DataFrame, target_path: str, estimated_record_count: int, estimated_row_bytes: int, target_file_size_bytes: int):
    total_estimated_csv_size_bytes = estimated_record_count * estimated_row_bytes
    num_partitions = max(1, round(total_estimated_csv_size_bytes / target_file_size_bytes))

    logger.info(f"--> DataFrame for {target_path} has an estimated {estimated_record_count} records.")
    logger.info(f"--> Using estimated CSV row size of {estimated_row_bytes} bytes. Total estimated CSV size: {round(total_estimated_csv_size_bytes / (1024**2))} MB.")
    logger.info(f"--> Coalescing into {num_partitions} partition(s) to target file size of {TARGET_FILE_SIZE_MB} MB.")

    df.coalesce(num_partitions) \
      .write \
      .format("csv") \
      .option("header", "true") \
      .option("compression", "none") \
      .option("escape", "\"") \
      .mode("overwrite") \
      .save(target_path)

def main():
    args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE_BUCKET', 'DESTINATION_BUCKET', 'SOURCE_PREFIX', 'DESTINATION_PREFIX'])

    global sc
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    logger = glueContext.get_logger()

    source_prefix = args.get('SOURCE_PREFIX', '').strip('/')
    destination_prefix = args.get('DESTINATION_PREFIX', '').strip('/')
    source_s3_path = os.path.join(f"s3a://{args['SOURCE_BUCKET']}", source_prefix)
    destination_s3_path = os.path.join(f"s3a://{args['DESTINATION_BUCKET']}", destination_prefix)

    total_input_bytes = get_total_input_size_bytes(spark, source_s3_path, logger)
    if total_input_bytes == 0:
        logger.info("--> Total input size is 0. No data to process. Exiting job.")
        job.commit()
        return

    estimated_record_count = round(total_input_bytes / ESTIMATED_BYTES_PER_JSON_RECORD)

    if estimated_record_count == 0:
        logger.info("--> Estimated record count is 0 based on input size. Exiting job.")
        job.commit()
        return

    schema = get_data_schema()
    source_df = spark.read.schema(schema).option("mode", "FAILFAST").json(source_s3_path)

    generated_token_df = create_generated_token_df(source_df)
    client_assertion_df = create_client_assertion_df(source_df)

    target_file_size_bytes = TARGET_FILE_SIZE_MB * 1024 * 1024

    spark.sparkContext.setJobGroup(
        "write_generated_token_csv",
        "Write generated_token_audit to CSV"
    )
    write_df_to_csv(
        logger=logger,
        df=generated_token_df,
        target_path=os.path.join(destination_s3_path, "generated_token_audit"),
        estimated_record_count=estimated_record_count,
        estimated_row_bytes=ESTIMATED_GENERATED_TOKEN_ROW_BYTES,
        target_file_size_bytes=target_file_size_bytes
    )

    spark.sparkContext.setJobGroup(
        "write_client_assertion_csv",
        "Write client_assertion_audit to CSV"
    )
    write_df_to_csv(
        logger=logger,
        df=client_assertion_df,
        target_path=os.path.join(destination_s3_path, "client_assertion_audit"),
        estimated_record_count=estimated_record_count,
        estimated_row_bytes=ESTIMATED_CLIENT_ASSERTION_ROW_BYTES,
        target_file_size_bytes=target_file_size_bytes
    )

    logger.info("--> ETL process completed successfully.")
    job.commit()

if __name__ == "__main__":
    main()
