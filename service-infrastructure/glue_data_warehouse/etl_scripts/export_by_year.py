import os
import sys
import tempfile
import zipfile

import boto3
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from boto3.s3.transfer import TransferConfig
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql import SparkSession

required_args = ["JOB_NAME", "TABLE_NAME", "S3_BUCKET", "DATABASE_NAME"]

if any(arg.startswith("--TABLE_NAME_RR") for arg in sys.argv):
    required_args.append("TABLE_NAME_RR")


# Get job arguments
args = getResolvedOptions(sys.argv, required_args)

sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Configuration
DATABASE_NAME = args["DATABASE_NAME"]
TABLE_NAME = args["TABLE_NAME"]
S3_BUCKET = args["S3_BUCKET"]
EPC_TYPE = args["TABLE_NAME"].replace("_", "-")
S3_PREFIX = f"full-load/"
S3_OUTPUT_PATH = f"s3://{S3_BUCKET}/{S3_PREFIX}"
ZIP_FILE_KEY = f"{S3_PREFIX}{EPC_TYPE}-csv.zip"
TABLE_NAME_RR = args.get("TABLE_NAME_RR")



sql_spark = (
    SparkSession.builder
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
    .config("spark.sql.catalog.glue_catalog.warehouse", S3_OUTPUT_PATH)
    .config("spark.sql.catalog.glue_catalog.job-language", "python")
    .getOrCreate()
)

s3_client = boto3.client("s3")

# Read data from Glue Catalog
frame = glueContext.create_data_frame.from_catalog(
    database=DATABASE_NAME, table_name=TABLE_NAME
)

# If this is changed, make sure to change service-infrastructure/data_frontend_delivery/lambda/functions/collect-user-filtered-data/index.py
column_ordering = {
    "domestic": ["certificate_number","address1","address2","address3","postcode","posttown","address","constituency", "constituency_label", "local_authority","local_authority_label","built_form","co2_emiss_curr_per_floor_area","co2_emissions_current","co2_emissions_potential","construction_age_band","current_energy_efficiency","current_energy_rating","energy_consumption_current","energy_consumption_potential","energy_tariff","environment_impact_current","environment_impact_potential","extension_count","fixed_lighting_outlets_count","flat_storey_count","flat_top_storey","floor_description","floor_energy_eff","floor_height","floor_level","glazed_area","glazed_type","heat_loss_corridor","heating_cost_current","heating_cost_potential","hot_water_cost_current","hot_water_cost_potential","hot_water_energy_eff","hot_water_env_eff","hotwater_description","inspection_date","lighting_cost_current","lighting_cost_potential","lighting_description","lighting_energy_eff","lighting_env_eff","lodgement_date","lodgement_datetime","low_energy_lighting","low_energy_fixed_lighting_outlets_count","main_fuel","mainheat_description","mainheat_energy_eff","mainheat_env_eff","mainheatc_energy_eff","mainheatc_env_eff","mainheatcont_description","main_heating_controls","mains_gas_flag","mechanical_ventilation","multi_glaze_proportion","number_habitable_rooms","number_heated_rooms","number_open_fireplaces","photo_supply","potential_energy_efficiency","potential_energy_rating","property_type","report_type","roof_description","roof_energy_eff","roof_env_eff","secondheat_description","sheating_energy_eff","sheating_env_eff","solar_water_heating_flag","tenure","total_floor_area","transaction_type","unheated_corridor_length","walls_description","walls_energy_eff","walls_env_eff","wind_turbine_count","windows_description","windows_energy_eff","windows_env_eff","floor_env_eff","region","country", "uprn", "uprn_source"],
    "non-domestic": ["certificate_number","address1","address2","address3","posttown","postcode","address","constituency","constituency_label","local_authority","local_authority_label","asset_rating","asset_rating_band","property_type","inspection_date","lodgement_date","lodgement_datetime","transaction_type","new_build_benchmark","existing_stock_benchmark","building_level","main_heating_fuel","other_fuel_desc","special_energy_uses","renewable_sources","floor_area","standard_emissions","target_emissions","typical_emissions","building_emissions","aircon_present","aircon_kw_rating","estimated_aircon_kw_rating","ac_inspection_commissioned","building_environment","report_type","primary_energy_value", "uprn", "uprn_source"],
    "display":      ["certificate_number","address1","address2","address3","posttown","postcode","address","constituency","constituency_label","local_authority","local_authority_label","current_operational_rating","yr1_operational_rating","yr2_operational_rating","electric_co2","heating_co2","renewables_co2","property_type","inspection_date","lodgement_date","lodgement_datetime","main_benchmark","main_heating_fuel","special_energy_uses","renewable_sources","total_floor_area","annual_thermal_fuel_usage","typical_thermal_fuel_usage", "typical_thermal_use", "annual_electrical_fuel_usage","typical_electrical_fuel_usage","renewables_fuel_thermal","renewables_electrical","yr1_electricity_co2","yr2_electricity_co2","yr1_heating_co2","yr2_heating_co2","yr1_renewables_co2","yr2_renewables_co2","aircon_present","aircon_kw_rating","estimated_aircon_kw_rating","ac_inspection_commissioned","building_environment","building_category","operational_rating_band","nominated_date","or_assessment_end_date","occupancy_level","report_type","other_fuel","country", "uprn", "uprn_source"],
    "domestic-rr": ["certificate_number","improvement_item","improvement_id","improvement_summary_text","improvement_descr_text","indicative_cost"],
    "non-domestic-rr": ["certificate_number","related_certificate_number","payback_type","recommendation_item","recommendation_code","recommendation"],
    "display-rr": ["certificate_number","related_certificate_number","payback_type","recommendation_item","recommendation_code","recommendation"]
}

if TABLE_NAME in column_ordering.keys():
    frame = frame.select(column_ordering[TABLE_NAME])

df = frame.withColumn("year", F.year(F.col("lodgement_date")))

# Get unique years
years = [
    row.year
    for row in df.select("year").filter(df["year"].isNotNull()).distinct().collect()
]


if TABLE_NAME_RR:
    logger.warn(f'Received table "{TABLE_NAME_RR}" for recommendations')

    df_rr = glueContext.create_data_frame.from_catalog(
        database=DATABASE_NAME, table_name=TABLE_NAME_RR
    )
    if TABLE_NAME_RR in column_ordering.keys():
        df_rr = df_rr.select(*column_ordering[TABLE_NAME_RR])

    if TABLE_NAME == "domestic":
        joined_df = (
            df.select("certificate_number", "year")
            .dropDuplicates(["certificate_number"])
            .join(df_rr, on="certificate_number", how="inner")
        )
    else:
        df_rr_selected = df_rr.select(
            *[col for col in df_rr.columns if col != 'certificate_number']
        )

        joined_df = (
            df.select("certificate_number", "year")
            .dropDuplicates(["certificate_number"])
            .join(df_rr_selected, df.certificate_number == df_rr_selected.related_certificate_number, "inner")
        )

def process_and_zip(df, table_name, years, zipf, csv_filename=None):
    if not csv_filename:
        csv_filename = table_name

    for year in years:
        logger.warn(f'Processing table "{table_name}" year: {year}')
        year_df = df.filter(F.col("year") == year).drop("year").repartition(1)

        output_folder = f"{S3_OUTPUT_PATH}{table_name}-{year}/"
        year_df.write.mode("overwrite").option("header", "true").option("escape", "\"").csv(output_folder)

        prefix = f"{S3_PREFIX}{table_name}-{year}/"
        response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)

        if "Contents" in response:
            for obj in response["Contents"]:
                if obj["Key"].endswith(".csv"):
                    logger.warn(f"Processing file: {obj['Key']}")
                    file_obj = s3_client.get_object(Bucket=S3_BUCKET, Key=obj["Key"])
                    zipf.writestr(f"{csv_filename}-{year}.csv", file_obj["Body"].read())

                    for obj in response["Contents"]:
                        s3_client.delete_object(Bucket=S3_BUCKET, Key=obj["Key"])
                    break  # Only process the first CSV file
        else:
            logger.warn(f'No CSV found for table "{table_name}" year {year}')


temp_dir = tempfile.gettempdir()
local_zip_path = os.path.join(temp_dir, f"{EPC_TYPE}-output.zip")

try:
    with zipfile.ZipFile(local_zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        logger.warn(f'Will start processing "{TABLE_NAME}"')
        process_and_zip(df, TABLE_NAME, years, zipf, csv_filename="certificates")

        if TABLE_NAME_RR:
            logger.warn(f'Will start processing "{TABLE_NAME_RR}" for recommendations')
            process_and_zip(joined_df, TABLE_NAME_RR, years, zipf, csv_filename="recommendations")

    chunk_size_bytes = 1024 * 1024 * 300
    logger.warn(f'Uploading {local_zip_path} to s3://{S3_BUCKET}/{ZIP_FILE_KEY} with chunk size {chunk_size_bytes}')

    config = TransferConfig(multipart_chunksize=chunk_size_bytes)

    s3_client.upload_file(
        Filename=local_zip_path,
        Bucket=S3_BUCKET,
        Key=ZIP_FILE_KEY,
        Config=config
    )
    logger.warn('Completed the upload successfully')

except Exception as e:
    logger.error(f'Error occurred: "{e}"')
    raise

finally:
    if os.path.exists(local_zip_path):
        os.remove(local_zip_path)
        logger.warn(f'Cleaned up local temporary file at {local_zip_path}')

job.commit()
