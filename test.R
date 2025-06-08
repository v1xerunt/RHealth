
devtools::load_all()
# test_inhospital_mortality_mimic4.R

data_dir <- "F:/R-project/mimic-iv-ehr/physionet.org/files/mimiciv/3.1"

cat("📦 初始化 MIMIC-IV 数据集...\n")
ds <- MIMIC4EHRDataset$new(
  root = data_dir,
  tables = c("patients", "admissions", "diagnoses_icd", "procedures_icd", "prescriptions"),
  dataset_name = "mimic4_ehr",
  dev = TRUE
)

ds$stats()



cat("🧠 设置 In-Hospital Mortality 任务...\n")
sd <- ds$set_task(task = Readmission30DaysMIMIC4$new())




cat("🧪 划分数据集...\n")
splits <- split_by_patient(sd, c(0.8, 0.1, 0.1))
train_dl <- get_dataloader(splits[[1]], batch_size = 32, shuffle = TRUE)
val_dl <- get_dataloader(splits[[2]], batch_size = 32)
test_dl <- get_dataloader(splits[[3]], batch_size = 32)

cat("🔧 构建 RNN 模型...\n")
model <- RNN$new(
  dataset = sd,
  embedding_dim = 128,
  rnn_type = "GRU",
  num_layers = 1
)

cat("🏋️‍♀️ 开始训练...\n")
trainer <- Trainer$new(model = model)
trainer$train(
  train_dataloader = train_dl,
  val_dataloader = val_dl,
  epochs = 10,
  optimizer_params = list(lr = 1e-3),
  monitor = "roc_auc"
)

cat("📈 模型评估...\n")
result <- trainer$evaluate(test_dl)
print(result)

cat("✅ 测试完成\n")
