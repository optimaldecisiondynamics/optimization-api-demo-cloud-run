library(plumber)
library(purrr)
library(dplyr)
library(zip)

# Source the post processing script as a function
source("./dog_path_analysis.R")

#* @apiTitle Puppy Petting Optimization Problem
#* @apiDescription Use this API to solve the Puppy Petting Optimization problem, petting as many dogs as possible on a walk from an origin to a destination!

#* Tell about what the API does
#* @serializer contentType list(type="application/octet-stream")
#* @post /mathadelic_woof
function(req, res) {
  
  # Upload zip file of data for the optimization model
  multipart <- mime::parse_multipart(req)
  
  fp <- purrr::pluck(multipart, 1, "datapath", 1)
  
  zip::unzip(zipfile = fp, 
             exdir = getwd(), overwrite = TRUE)
  
  # Delete the zip file
  file.remove(fp)
  
  # Run the optimization model!
  system(command = "python3 dog_max_path.py",
         wait = TRUE)
  
  # Create folder for solution files
  dir.create("woof_output")
  
  dog_maximizer_post_processor()
  
  # copy files to the solution directory
  solution_files <- c("dog_maximizing_path.csv",
                      "total_travel_time.csv")
  file.copy(from = solution_files,
            to = paste0("woof_output/",
                        solution_files))
  
  # Sending the solution back in a zip file because there are 2 CSVs to send back
  zfile <- tempfile(fileext = ".zip")
  
  zip::zip(zipfile = zfile,
           files = paste0("woof_output/", solution_files))
  
  readBin(zfile, "raw", n = file.info(zfile)$size)
  
}