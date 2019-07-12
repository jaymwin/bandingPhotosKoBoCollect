
library(tidyverse)
library(here)
library(fs)
library(furrr)

future::plan(multiprocess)

photos <- dir_ls(path = here('renamed_images'), glob = '*.jpg')

photos <- photos %>%
  as_tibble() %>%
  mutate(
    banding_photos = str_c('Z:/HeathLab/American Kestrel projects/Full_Cycle_Phenology/Banding Photos/', basename(value))
    )

move_photos <- as_mapper(~file_move(path = ..1, 
                                    new_path = ..2))
photos %>%
  future_pmap_chr(move_photos)
