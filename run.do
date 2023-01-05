** Rebecca Joseph, University of Nottingham, 2023
** File: run.do
** Requires: Created using Stata MP v17. Requires Stata v16 (frames function)
** Desc: running this do-file will call the 3 do-files in the correct order
** Use: set working directory at line 7

cd "[filepath]/KTP_tasks"

do cleaning_datasets.do
do summary_tables.do
do graphs.do

frames reset
exit
