# Checking (yesterday's) word list against words already observed

library(readr)
t0 <- Sys.time()

# Known words (this is a large wordlist compiled from DeReKoGram and older RSS feeds from 2020 to 2025)
known <- read_lines("/home/pi/Data/RSS_DRK_intersect.txt", num_threads = 3, progress = F)
cat("Known words read.\n")

# All previous new words
previously_new <- list.files("/home/pi/Data/new_word_lists/",
                             pattern = "^New_words",
                             full.names = T)
prev_new_word_lists <- dplyr::bind_rows(lapply(previously_new, function (f) {
  read_tsv(f, col_types = "ci", progress = F)
}))
cat(nrow(prev_new_word_lists), "previously new words read.\n")
prev_new_words <- prev_new_word_lists$wordform

# Yesterday's words (potential new words)
date_to_check <- Sys.Date() - 1
wordlist_file <- paste0("/home/pi/Data/Feed_wordlist_",
                        as.character(date_to_check),
                        ".txt")
list_to_check <- read_tsv(wordlist_file, col_types = "ci", progress = F) 

# Check list against known
cat("Now checking for new words...\n")
new_word_list <- list_to_check[!(list_to_check$wordform %in% known), ]
new_word_list <- new_word_list[!(new_word_list$wordform %in% prev_new_words), ]
cat(nrow(new_word_list), "new words found.\n")

# Saving new words
output_file <- paste0("/home/pi/Data/new_word_lists/New_words_",
                      as.character(date_to_check),
                      ".txt")
write.table(new_word_list, file = output_file,
            sep = "\t",
            row.names = F,
            col.names = T,
            quote = F)
cat("New word list written. Done in", round(difftime(Sys.time(), t0, units = "mins")), "minutes.\n")
