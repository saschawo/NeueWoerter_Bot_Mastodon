library(rtoot)
library(lubridate)

yesterday <- today()-1

fname <- paste0("~/Data/new_word_lists/New_words_", yesterday, ".txt")

new_words_today <- read.csv(fname, header = T, sep = "\t")

cat("Read", nrow(new_words_today), "new words from yesterday.\n")

top5 <- new_words_today[1:5,]
rest <- new_words_today[6:nrow(new_words_today),]
random5 <- dplyr::slice_sample(rest, n = 5)
random5_without_dash <- dplyr::slice_sample(rest[!grepl("-", rest$wordform),], n = 5)

cat("Word selection finished.\n")

german_date <- paste0(day(yesterday), ".", month(yesterday), ".", year(yesterday))

intros <- c(paste0("Diese Wörter wurden gestern (", german_date, ") zum ersten Mal gesichtet."),
            paste0("Diese Wörter habe ich gestern (", german_date, ") erstmals entdeckt."),
            paste0("Welche Wörter waren gestern (", german_date, ") neu?"),
            paste0("Was haben wir vor gestern (", german_date, ") noch nie gelesen?"),
            paste0("Und was gabs gestern (", german_date, ") Neues?"),
            paste0("Gestern (", german_date, ") hab ich diese Wortformen zum ersten Mal gesehen."),
            paste0("Neue Wörter am ", german_date, ":"),
            paste0("Ich hab mal wieder ein paar neue Wörter entdeckt. Diese hier gabs gestern am ", german_date, ":"),
            paste0("Diese Wortformen hier habe ich gestern, den ", german_date, ", zum ersten Mal gesehen."),
            paste0("NEU NEU NEU - Zum ersten Mal gestern (", german_date, ") entdeckt:"),
            paste0("Jeden Tag find ich neue Wortformen. Gestern (", german_date, ") waren es diese hier."),
            paste0("Auch heute bringt Euch der Neue-Wörter-Bot noch nie dagewesene Wörter vom Vortag (", german_date, ")!"))

top5_text <- paste0(top5$wordform, ": ", top5$freq, "x")
random5_text <- paste0(random5$wordform, ": ", random5$freq, "x")
random5_without_dash_text <- paste0(random5_without_dash$wordform, ": ", random5$freq, "x")

toot <- paste0(sample(intros, 1), "\n\n",
               "~~~TOP 5~~~\n\n",
               paste(top5_text, collapse = "\n"),
               "\n\n~~~Zufällige 5 andere~~~\n\n",
               paste(random5_text, collapse = "\n"),
               "\n\n~~~Zufällige 5 ohne Bindestrich~~~\n\n",
               paste(random5_without_dash_text, collapse = "\n"),
               "\n\nInsgesamt habe ich gestern ", nrow(new_words_today), " neue Wortformen entdeckt.\n\n#neuewoerter")
cat("Toot built.\n")
post_toot(toot)
cat("Success!\n")