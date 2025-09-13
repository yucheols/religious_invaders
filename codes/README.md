# Running niche modeling R scripts on Mendel HPC

## Things to watch out for
- Always use absolute path when loading and writing files
- Check write permissions
- Save outputs to permanent storage folders
- When running multiples jobs, give each a unique job name, and use unique file names
- Make sure to install all necessary R packages beforehand
- Load conda environment that contains the right R version
- Use sessionInfo() to log R and package versions used - this ensures reproducibility
- Request enough computing resources
- When running a job in parallel, use parallel::detecCores() or similar functions to check the number of available cores
- Log output and error files using .out and .err
- Test locally using smaller dataset