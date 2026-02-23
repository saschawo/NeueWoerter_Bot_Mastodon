library(rtoot)
library(lubridate)
library(stringr)

toot_token <- readRDS("/home/pi/.config/R/rtoot/rtoot_token.rds")

yesterday <- today()-1

fname <- paste0("~/Data/new_word_lists/New_words_", yesterday, ".txt")

new_words_today <- read.csv(fname, header = T, sep = "\t")

cat("Read", nrow(new_words_today), "new words from yesterday.\n")

# New selection criterion:
# String has to contain more letters than numbers.
new_words_today$n_digits <- str_count(new_words_today$wordform, "[[:digit:]]")
new_words_today$n_letters <- str_count(new_words_today$wordform, "[[:alpha:]]")
new_words_today <- new_words_today[new_words_today$n_letters > new_words_today$n_digits,]

top5 <- new_words_today[1:5,]
rest <- new_words_today[6:nrow(new_words_today),]
random5 <- dplyr::slice_sample(rest, n = 5)
rest2 <- rest[!rest$wordform %in% random5$wordform,]
random5_without_dash <- dplyr::slice_sample(rest2[!grepl("-", rest2$wordform),], n = 5)

cat("Word selection finished.\n")

german_date <- paste0(day(yesterday), ".", month(yesterday), ".", year(yesterday))

intros <- c(paste0("Diese Wörter wurden gestern (", german_date, ") zum ersten Mal gesichtet."),
            paste0("Diese Wörter habe ich gestern (", german_date, ") erstmals entdeckt."),
            paste0("Welche Wörter waren gestern (", german_date, ") neu?"),
            paste0("Was haben wir vor gestern (", german_date, ") noch nie gelesen?"),
            paste0("Und was gabs gestern (", german_date, ") Neues?"),
            paste0("Gestern (", german_date, ") hab ich diese Wortformen zum ersten Mal gesehen."),
            paste0("Neue Wörter am ", german_date, ":"),
            paste0("Ich hab mal wieder ein paar neue Wörter. Diese hier gabs gestern am ", german_date, ":"),
            paste0("Diese Wortformen habe ich gestern, den ", german_date, ", zum ersten Mal gesehen."),
            paste0("NEU NEU NEU - Zum ersten Mal gestern (", german_date, ") entdeckt:"),
            paste0("Jeden Tag find ich neue Wortformen. Gestern (", german_date, ") waren es diese hier."),
            paste0("Auch heute noch nie dagewesene Wörter vom Vortag (", german_date, ")!"),
            paste0("Gestern, am ", german_date, " waren diese Wortformen neu:"),
            paste0("Mal wieder neue Wörter von mir! Diese hier gabs am ", german_date, ":"))

top5_text <- paste0(top5$wordform, ": ", top5$freq, "x")
random5_text <- paste0(random5$wordform, ": ", random5$freq, "x")
random5_without_dash_text <- paste0(random5_without_dash$wordform, ": ", random5$freq, "x")

toot <- paste0(sample(intros, 1), "\n\n",
               "~TOP 5~\n\n",
               paste(top5_text, collapse = "\n"),
               "\n\n~Zufällige 5~\n\n",
               paste(random5_text, collapse = "\n"),
               "\n\n~Zufällige 5 ohne Bindestrich~\n\n",
               paste(random5_without_dash_text, collapse = "\n"),
               "\n\nGestern habe ich ", nrow(new_words_today), " neue Wortformen entdeckt.\n\n#neuewoerter")
cat("Toot built.\n")

while (nchar(toot) > 500) {
  cat("Zu lang! Ich baue nochmal einen...\n")
  toot <- paste0(sample(intros, 1), "\n\n",
                 "~TOP 5~\n\n",
                 paste(top5_text, collapse = "\n"),
                 "\n\n~Zufällige 5~\n\n",
                 paste(random5_text, collapse = "\n"),
                 "\n\n~Zufällige 5 ohne Bindestrich~\n\n",
                 paste(random5_without_dash_text, collapse = "\n"),
                 "\n\nGestern habe ich ", nrow(new_words_today), " neue Wortformen entdeckt.\n\n#neuewoerter")
}

# Just to be sure, we're checking whether a toot has already been posted today before posting another.
id <- "115949213502023674"
most_recent_toot_date <- as.character(as.Date(get_account_statuses(id, token = toot_token)[1,]$created_at))
cat("Most recent toot date is", most_recent_toot_date, "\n")
if (most_recent_toot_date != today()) {
  post_toot(status = toot, token = toot_token, verbose = T)
}
cat("Done!\n")


