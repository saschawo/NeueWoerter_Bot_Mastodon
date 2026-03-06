rm(list=ls())

library(dplyr)
library(lubridate)
library(stringr)
library(parallel)
library(tidyr)
library(rtoot)
library(ggplot2)

# Load feed wordlists (all words) -----------------------------------------

# All saved feed wordlists
wl_files <- list.files("~/Data", pattern = "^Feed_wordlist",
                       full.names = T)

# Read wordlists and extract date from filename
wl_read <- mclapply(wl_files, mc.cores = 3,
                    FUN = function (x) {
                      rf <- read.table(x, sep = "\t", header = T)
                      rf$date <- str_extract(basename(x),
                                             "202[0-9]-[0-9][0-9]-[0-9][0-9]")
                      rf
                    })
wl_read <- bind_rows(wl_read)

# Load lists of new words per day -----------------------------------------

nwl_files <- list.files("~/Data/new_word_lists", pattern = "^New_words",
                        full.names = T)
nwl_read <- lapply(nwl_files,
                   FUN = function (x) {
                     rf <- read.table(x, sep = "\t", header = T)
                     rf$date <- str_extract(basename(x),
                                            "202[0-9]-[0-9][0-9]-[0-9][0-9]")
                     rf
                   })
nwl_read <- bind_rows(nwl_read)

# restrict all words to new words only
only.new <- wl_read[wl_read$wordform %in% nwl_read$wordform,]
days.total <- length(unique(only.new$date))


# Create wf_info ('wordform info') ----------------------------------------
# 'wf_info' holds number of days, percentage of days, total frequency, and newest date for each new wordform

wf_info <- only.new %>% group_by(wordform) %>%
  summarise(n.days.total = n(),
            p.days.total = n()/days.total,
            freq.total = sum(freq),
            new_on = min(date)) %>%
  arrange(-p.days.total, -freq.total)

# Merge newest date to only.new
only.new <- merge(only.new, wf_info[,c("wordform", "new_on")], by = "wordform")

# Exclude words here
exclusions <- c("4k-heimkinotest",
                "januar-sicherheitsupdates",
                "audio-briefing",
                "redaktoren-stimme",
                "mdm-grundlagen",
                "faz-wissenstest",
                "unternehmen-liveblog",
                "leserformat")
only.new <- only.new[!only.new$wordform %in% exclusions,]

# String has to contain more letters than numbers.
only.new$n_digits <- str_count(only.new$wordform, "[[:digit:]]")
only.new$n_letters <- str_count(only.new$wordform, "[[:alpha:]]")
only.new <- only.new[only.new$n_letters > only.new$n_digits,]

# Only words that have been found last month
new.lm <- only.new %>% filter(year(new_on) == year(rollback(today())) &
                                month(new_on) == month(rollback(today())) &
                                year(date) == year(rollback(today())) &
                                month(date) == month(rollback(today())))
# In the last month: Seen on how many days? Summed frequency?
## Number of days last month
total_days <- length(floor_date(rollback(today()), unit = "month"):rollback(today()))

wf_info.lm <- new.lm %>% group_by(wordform) %>%
  summarise(n_days = n(),
            total_freq = sum(freq)) %>%
  mutate(p_days = n_days/total_days) %>%
  arrange(-n_days, -total_freq)

# Merge new.lm with wf_info.lm
new.lm <- merge(new.lm, wf_info.lm, by = "wordform")

# Get top words last month
top_words <- wf_info.lm[1:25,]$wordform

# All dates in last month
date_seq <- seq(floor_date(rollback(today()), unit = "month"), rollback(today()), unit = "day")

# Prepare tibble for each top word and each day
grid <- expand_grid(
  wordform = top_words,
  date = date_seq
)

df_top <- new.lm %>%
  filter(wordform %in% top_words) %>%
  mutate(date = as.Date(date))

plot_data <- grid %>%
  left_join(df_top, by = c("wordform", "date")) %>%
  mutate(freq = replace_na(freq, 0)) %>%
  mutate(wordform = factor(wordform, levels = rev(top_words)))

ggplot(plot_data, aes(x = date, y = wordform, fill = freq)) +
  geom_tile(color = "white", linewidth = 0.2, width = .9, height = .9) +
  scale_fill_gradient(
    low = "grey90",
    high = "darkgreen",
    trans = "sqrt",      # improves contrast for skewed freq
    name = "Frequency", guide = "none"
  ) +
  scale_x_date(date_breaks = "1 week", date_labels = "%d.%m.%y") +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    axis.title = element_blank(),
    axis.text.y = element_text(size = 12)
  )
# 1280 × 720px
plot.fname <- paste0("~/Plots/month_plot_", format.Date(rollback(today()), "%y-%m"), ".png")
ggsave(plot.fname,
       width = 1280, height = 720, units = "px", dpi = 150)

# Toot --------------------------------------------------------------------

german.months <- c("Januar", "Februar", "März", "April",
                   "Mai", "Juni", "Juli", "August",
                   "September", "Oktober", "November", "Dezember")
month.ger <- german.months[month(rollback(today()))]

toot_token <- readRDS("/home/pi/.config/R/rtoot/rtoot_token.rds")
toot_text <- paste0("~~~Zusammenfassung für ", month.ger, " ", year(rollback(today())), "~~~\n\n",
                    "Ich habe ", nrow(wf_info.lm), " neue Wortformen entdeckt. Das hier ist die Top 25.")
alt_text <- paste0("Wortformen, die im ",
                   month.ger, " ", year(rollback(today())),
                   " zum ersten Mal beobachtet wurden. Gezeigt sind die 25 häufigsten Wortformen (erst sortiert nach Anzahl Tagen, dann nach Anzahl Nennungen): ",
                   paste(top_words, collapse = ", "))
ret.val <- post_toot(status = toot_text,
                     alt_text = alt_text,
                     media = plot.fname,
                     token = toot_token)
print(ret.val)
cat("Done.\n")

