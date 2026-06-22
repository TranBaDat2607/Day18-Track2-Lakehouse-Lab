# Reflection — Top 5 Lakehouse Anti-Patterns

> **DRAFT — personalize before submitting.** Replace the bracketed bits and
> adjust the argument to your own team/project. Keep it under 200 words.

**Anti-pattern our team is most at risk of: the small-file problem (death by a
thousand tiny files).**

Our ingestion is streaming-shaped: many small batches landing continuously,
exactly like the 200 × 5K-row appends in NB2 that produced 200 files. Left
alone, each query pays a per-file open/stat/metadata cost, the transaction log
bloats, and point lookups crawl — NB2 measured a `~1680 ms` point query collapse
to `~25 ms` (66× faster) after `OPTIMIZE` + `Z-ORDER`, purely from compaction
(200 → 55 files) and min/max file-skipping (only 1 of 55 files had to be read).

Why us specifically: we optimize for write latency, so the temptation is to
"just append and move on" and never schedule compaction. The fix is operational,
not heroic — a periodic `OPTIMIZE`/`compact()` + `Z-ORDER` on the high-traffic
columns we filter by, plus partitioning by date so the layout stays prunable.

Runner-up risk: treating Bronze as the serving layer (no Silver dedup) — NB4
showed `9,948` duplicate retries silently inflating every Gold metric until the
`request_id` dedup dropped Bronze 200K → Silver 190,052.

— *[Trần Bá Đạt - 2A202600778]*
