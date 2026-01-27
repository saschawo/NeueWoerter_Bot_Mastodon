# NeueWoerter_Bot_Mastodon
Ein Bot, der RSS-Feeds durchsucht und neue Wörter auf Mastodon postet

Der Bot postet auf [@neuewoerter_bot@mastodon.social](https://mastodon.social/@neuewoerter_bot).

Die Logik der Scripts ist:
1. get_and_process_feeds_github.R holt sich gespeicherte RSS-Feeds von einem anderen Raspberry Pi im gleichen Netzwerk (Adresse ist im Script anonymisiert) und erstellt eine Wortliste für den aktuellen Tag.
2. check_new_words_github.R lädt Listen "alter" Wörter, gleicht diese mit der neuen Wortliste ab und speichert die Liste neuer Wörter.
3. post_new_words_mastodon.R lädt die Liste neuer Wörter für den aktuellen Tag, selektiert einige Wörter, baut den Toot-Text zusammen und postet am Ende.
