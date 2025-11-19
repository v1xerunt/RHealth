# Helper functions for OMOP testing

#' Create dummy OMOP test data
#' @param data_dir Directory to write CSV files
#' @return NULL (side effect: creates CSV files)
create_omop_test_data <- function(data_dir) {
  dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
  
  # person
  person <- data.frame(
    person_id = 1:2,
    gender_concept_id = c(8507, 8532),
    year_of_birth = c(1980, 1990),
    month_of_birth = c(1, 5),
    day_of_birth = c(15, 20),
    birth_datetime = c("1980-01-15 00:00:00", "1990-05-20 00:00:00"),
    race_concept_id = c(8527, 8527),
    ethnicity_concept_id = c(NA, NA),
    location_id = c(NA, NA),
    provider_id = c(NA, NA),
    care_site_id = c(NA, NA),
    person_source_value = c(NA, NA),
    gender_source_value = c(NA, NA),
    gender_source_concept_id = c(NA, NA),
    race_source_value = c(NA, NA),
    race_source_concept_id = c(NA, NA),
    ethnicity_source_value = c(NA, NA),
    ethnicity_source_concept_id = c(NA, NA)
  )
  write.csv(person, file.path(data_dir, "person.csv"), row.names = FALSE)
  
  # visit_occurrence
  # Person 1: visits 31 days apart (for readmission=0 when time_window=15)
  # Person 2: visits 10 days apart (for readmission=1 when time_window=15)
  visit <- data.frame(
    visit_occurrence_id = c(101, 102, 103, 104),
    person_id = c(1, 1, 2, 2),
    visit_concept_id = c(9201, 9201, 9201, 9201),
    visit_start_date = c("2020-01-01", "2020-02-01", "2021-01-01", "2021-01-11"),
    visit_start_datetime = c("2020-01-01 10:00:00", "2020-02-01 10:00:00", "2021-01-01 10:00:00", "2021-01-11 10:00:00"),
    visit_end_date = c("2020-01-02", "2020-02-02", "2021-01-02", "2021-01-12"),
    visit_end_datetime = c("2020-01-02 10:00:00", "2020-02-02 10:00:00", "2021-01-02 10:00:00", "2021-01-12 10:00:00"),
    visit_type_concept_id = c(NA, NA, NA, NA),
    provider_id = c(NA, NA, NA, NA),
    care_site_id = c(NA, NA, NA, NA),
    visit_source_value = c(NA, NA, NA, NA),
    visit_source_concept_id = c(NA, NA, NA, NA),
    admitting_source_concept_id = c(NA, NA, NA, NA),
    admitting_source_value = c(NA, NA, NA, NA),
    discharge_to_concept_id = c(NA, NA, NA, NA),
    discharge_to_source_value = c(NA, NA, NA, NA),
    preceding_visit_occurrence_id = c(NA, NA, NA, NA)
  )
  write.csv(visit, file.path(data_dir, "visit_occurrence.csv"), row.names = FALSE)
  
  # death - set death between visit 101 (2020-01-01) and visit 102 (2020-02-01)
  death <- data.frame(
    person_id = c(1),
    death_date = c("2020-01-15"),
    death_datetime = c("2020-01-15 10:00:00"),
    death_type_concept_id = c(38003569),
    cause_concept_id = c(NA),
    cause_source_value = c(NA),
    cause_source_concept_id = c(NA)
  )
  write.csv(death, file.path(data_dir, "death.csv"), row.names = FALSE)
  
  # condition_occurrence - add condition for visit 103 (person_id=2)
  condition <- data.frame(
    condition_occurrence_id = c(201, 202, 203),
    person_id = c(1, 1, 2),
    condition_concept_id = c(111, 222, 555),
    condition_start_date = c("2020-01-01", "2020-02-01", "2021-01-01"),
    condition_start_datetime = c("2020-01-01 10:00:00", "2020-02-01 10:00:00", "2021-01-01 10:00:00"),
    condition_end_date = c(NA, NA, NA),
    condition_end_datetime = c(NA, NA, NA),
    condition_type_concept_id = c(NA, NA, NA),
    stop_reason = c(NA, NA, NA),
    provider_id = c(NA, NA, NA),
    visit_occurrence_id = c(101, 102, 103),
    visit_detail_id = c(NA, NA, NA),
    condition_source_value = c(NA, NA, NA),
    condition_source_concept_id = c(NA, NA, NA),
    condition_status_source_value = c(NA, NA, NA),
    condition_status_concept_id = c(NA, NA, NA)
  )
  write.csv(condition, file.path(data_dir, "condition_occurrence.csv"), row.names = FALSE)
  
  # procedure_occurrence - add procedure for visit 103
  procedure <- data.frame(
    procedure_occurrence_id = c(301, 302),
    person_id = c(1, 2),
    procedure_concept_id = c(333, 666),
    procedure_date = c("2020-01-01", "2021-01-01"),
    procedure_datetime = c("2020-01-01 11:00:00", "2021-01-01 11:00:00"),
    procedure_type_concept_id = c(NA, NA),
    modifier_concept_id = c(NA, NA),
    quantity = c(NA, NA),
    provider_id = c(NA, NA),
    visit_occurrence_id = c(101, 103),
    visit_detail_id = c(NA, NA),
    procedure_source_value = c(NA, NA),
    procedure_source_concept_id = c(NA, NA),
    modifier_source_value = c(NA, NA)
  )
  write.csv(procedure, file.path(data_dir, "procedure_occurrence.csv"), row.names = FALSE)
  
  # drug_exposure - add drug for visit 103
  drug <- data.frame(
    drug_exposure_id = c(401, 402),
    person_id = c(1, 2),
    drug_concept_id = c(444, 777),
    drug_exposure_start_date = c("2020-01-01", "2021-01-01"),
    drug_exposure_start_datetime = c("2020-01-01 12:00:00", "2021-01-01 12:00:00"),
    drug_exposure_end_date = c(NA, NA),
    drug_exposure_end_datetime = c(NA, NA),
    verbatim_end_date = c(NA, NA),
    drug_type_concept_id = c(NA, NA),
    stop_reason = c(NA, NA),
    refills = c(NA, NA),
    quantity = c(NA, NA),
    days_supply = c(NA, NA),
    sig = c(NA, NA),
    route_concept_id = c(NA, NA),
    lot_number = c(NA, NA),
    provider_id = c(NA, NA),
    visit_occurrence_id = c(101, 103),
    visit_detail_id = c(NA, NA),
    drug_source_value = c(NA, NA),
    drug_source_concept_id = c(NA, NA),
    route_source_value = c(NA, NA),
    dose_unit_source_value = c(NA, NA)
  )
  write.csv(drug, file.path(data_dir, "drug_exposure.csv"), row.names = FALSE)
  
  invisible(NULL)
}
