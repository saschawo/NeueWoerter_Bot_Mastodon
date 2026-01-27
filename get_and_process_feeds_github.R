# We copy (yesterday's) feeds from tastyPi, do some checks and analyze them.

t0 <- Sys.time()

suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(stringr))
suppressPackageStartupMessages(library(parallel))

make.words <- function (text) {
  text <- gsub('["–,.()«»%„“”?!+;‚‘]', "", text) # remove punctuation
  text <- gsub('&#034;|</i>|<i>|&#039|&#034|<strong>|</strong>|<strong|</li>|<li>|</ul>|<ul|idlist>', "", text) # remove patterns
  text <- str_trim(text) # trimming
  text <- gsub('[[:space:] ]+', " ", text) # remove multi-spaces
  text <- tolower(paste(text, collapse = " ")) # tolower
  text <- strsplit(text, " ")[[1]] # splitting
  text <- gsub(':$', "", text) # remove trailing colon
  text <- text[!(text %in% c("t-onlinede-redakteurin",
                             "sport-live-blog",
                             "t-onlinede",
                             "alibabade"
                             "focus-online-redakteur",
                             "focus-online-reporter",
                             "spiegel-titelstory",
                             "faz-sprinter",
                             "heise",
                             "derstandardat",
                             "km/h"))] # remove specific words
  text <- grep("https//wwwyoutubecom/watch", text, value = T, invert = T) # remove matches
  text <- grep("^[[:digit:]]+$", text, value = T, invert = T) # remove numbers only
  text
}

# Copying
copy_date <- today()-1
call <- paste0("scp [user, IP, and directory on/of another Raspberry Pi in the same network]",
               copy_date, 
               "* /home/pi/Data/Feeds/")
call_res <- system(call, intern = T)

# Check number of files
files <- list.files("/home/pi/Data/Feeds/",
                    pattern = as.character(copy_date),
                    full.names = T)
n_files <- length(files)
cat(n_files, "files copied (should be 24).\n")
stopifnot(n_files > 0)

# Process feeds
feeds <- bind_rows(lapply(files, readRDS))
cat(nrow(feeds), "feed items after initial read.\n")
feeds <- unique(feeds)
cat(nrow(feeds), "feed items after initial deduplication.\n")
feeds$text <- paste0(coalesce(feeds$title, ""), " ", coalesce(feeds$description, ""))
unq.texts <- unique(feeds$text)
cat(length(unq.texts), "unique texts identified.\n")

# Deleting copied files
rm_res <- file.remove(files)

# Make words
words <- unlist(mclapply(unq.texts, make.words, mc.cores = detectCores()-1))
cat(length(words), "tokens extracted from unique texts.\n")
words <- words[nchar(words) >= 2] # at least 2 chars
words <- words[grepl("^[[:alnum:]äöüß-]+$", words)] # only alpha, nums, dot and dash
words <- words[grepl("[[:alpha:]äöüß]", words)] # at least one alpha
words <- words[!grepl("[-]$", words)] # exclude dash at end
words <- words[!grepl("^[-]", words)] # exclude dash at beginning
cat(length(words), "tokens remain after filtering.\n")
word_freqs <- as.data.frame(table(words))
names(word_freqs) <- c("wordform", "freq")
word_freqs <- word_freqs %>% arrange(-freq)
cat(nrow(word_freqs), "unique wordforms identified.\n")

# Save word list
output_file <- paste0("/home/pi/Data/Feed_wordlist_",
                      as.character(copy_date),
                      ".txt")
write.table(word_freqs, file = output_file,
            sep = "\t",
            row.names = F,
            col.names = T,
            quote = F)
cat("Word list written. Done in", round(difftime(Sys.time(), t0, units = "secs")), "seconds.\n")