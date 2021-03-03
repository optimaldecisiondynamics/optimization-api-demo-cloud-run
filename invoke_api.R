library(httr)
library(dplyr)

woof_test <- POST("https://dog-petting-optimization-xgyk4omuna-ue.a.run.app/mathadelic_woof",
                  body = list(param = upload_file("dog_path_inputs.zip")),
                  write_disk("woof_output.zip", overwrite = TRUE))