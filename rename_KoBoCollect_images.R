
library(tidyverse)
library(readxl)
library(here)


# Find/unzip data ---------------------------------------------------------

# find paths to excel and zip files downloaded from KoBo website (these should be together with this script in same folder)
excel <- list.files(path = here(), pattern = '.xlsx')
zip <- list.files(path = here(), pattern = '.zip')

# unzip the photos
unzip(zip, exdir = here())


# read in banding data and image paths and join -------------------------------------------

dat <- read_excel(here(excel))

# grab relevant columns (band number, transmitter ID if no band, and photo types)
dat <- dat %>%
  select(markerID, transmitterID, date, tailPhoto, frontPopsiclePhoto, backPopsiclePhoto, frontWingPhoto, backWingPhoto, otherPhoto)

# if a bird is not banded (i.e., tag attached only), use Argos ID instead
dat <- dat %>%
  mutate(
    transmitterID = as.character(transmitterID),
    markerID = case_when(
      is.na(markerID) ~ str_c(transmitterID, 'tag'),
      TRUE ~ markerID
    )
  ) %>%
  select(-transmitterID)

# change format so photo columns become variable in column 'photo_type'
dat <- dat %>% 
  gather(key = "photo_type", value = "fileName", 3:8) %>%
  filter(!is.na(fileName)) %>% # get rid of NA's (missing or not taken photos)
  arrange(markerID, photo_type) # organize by bird and photo type

# create tibble of photos to be named
rawPhotos <- list.files(path = here(), pattern = '.jpg', full.names = FALSE, recursive = TRUE) %>%
  enframe(name = NULL) %>%
  rename(path = value) %>%
  mutate(fileName = str_sub(path, start = -17, end = -1))

# join photos with banding data
dat <- dat %>%
  left_join(., rawPhotos) %>%
  select(-fileName)


# now loop through each bird and type of photo -------------------------

# adapted from function for naming images and reading links: https://stackoverflow.com/questions/54262620/downloading-images-using-curl-library-in-a-loop-over-data-frame
rename_photos <- as_mapper(~file.rename(from = ..4, 
                                        to = str_c(here('renamed_images'), '/', ..1,"_",..2,"_",..3,".jpg")))

# create a folder to put renamed images in
dir.create(here('renamed_images'))

# rename jpgs and put in 'renamed_images' folder using purrr::pmap_chr
dat %>%
  pmap_chr(rename_photos)
