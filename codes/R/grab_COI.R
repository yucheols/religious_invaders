######  Download genbank sequences 

# clean working env
rm(list = ls(all.names = T))
gc()

# load packages
library(rentrez)
library(dplyr)


#####  download sequences
# automate
 
#  This function works very nicely when the accession numbers are already organized into a .csv file (e.g., as a Supplementary Material accompanying the paper).
#  Argument "seq_acc": a data.frame, with each column header having the sequence name, and one accession number per row
#  Argument "out.dir": path to output directory
#  example: fetch_genbank(seq_acc = seq_data, out.dir = 'path/to/directory')

#  Warning: This function should be loaded again if you restart R

fetch_genbank <- function (seq_acc, out.dir) {
  seq_list <- list()
  
  for (i in 1:ncol(seq_acc)) {
    seq_get <- entrez_fetch(db = 'nuccore', id = na.omit(seq_acc[[i]]), rettype = 'fasta', retmode = 'text')
    seq_list[[i]] <- seq_get
    fasta_txt <- paste(seq_get, collapse = '\n')
    writeLines(fasta_txt, paste0(out.dir, colnames(seq_acc)[i], '.fasta'))
  }
  print('done')
}


#####  load data
# load data
seq_data <- read.csv('data/COI_seq/Shim_Song_2024_suppl.csv')
head(seq_data)

# run!
fetch_genbank(seq_acc = data.frame(COI = seq_data[, c('COI')]), out.dir = 'data/COI_seq/')
#fetch_genbank(seq_acc = seq_data %>% dplyr::select('COI'), out.dir = 'data/COI_seq/')     # same thing but using dplyr
