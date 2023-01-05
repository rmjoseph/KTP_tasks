# KTP_tasks

This repository contains Stata do-files created with Stata MP v17.

## List of files
* **run.do** - run this file in Stata to call all the scripts. The file path in line 7 should be updated.
* **cleaning_datasets.do** - data preparation step, cleans and combines the variables
* **summary_tables.do** - outputs descriptive tables
* **graphs.do** - outputs graphs

## Requirements
* This repository contains no datasets. The files "Task4_ehr_demographics.csv" and "Task4_app_data.csv" should be moved into the project directory before running the scripts.
* Stata v16 or later is needed as the frames function is used.
* One additional package is required (cleanplots) - this is installed within the code.

## Running the code
* Assumes all files are in a single directory
* Edit line 7 of file "run.do" to update the path to the project directory
* Open "run.do" in Stata and run from the command line (first time, "do [filepath]/run.do") or using the do-file editor




