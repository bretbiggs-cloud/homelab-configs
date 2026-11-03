# Movie metadata repair — November2,2026

## Scope and method

User requested reviewing and fixing movie metadata. Authorized changes are Jellyfin metadata only: no media renaming, relocation, deletion, library-root changes, kids-folder sorting, account changes or downloads. Existing Jellyfin media bind remains read-only. This work does not modify movie quality or repair corrupt video files.

Initial audit returned1555 movie entries:916 withoutTMDb IDs,787 without synopsis,249 without production year, and1 without a primary image.616 entries have episode/season patterns despite being in Movies; additional series and short sample/intro clips require separate classification. Counts describe library entries, not1555 distinct full-length films.

Repair-JellyfinMovieMetadata.ps1 searches TheMovieDb using cleaned title and explicit year, applies only a unique exact normalized-title/year result, and verifies the provider ID and unchanged path. Normalization handles punctuation, accents and ampersands; no fuzzy match selection. Existing provider matches are retained, with missing fields requested where needed. Locked items and ambiguous results are held for review. Two workers maximum, disjoint by item-ID shard, with resumable private result files.

Apply-ReviewedJellyfinMetadata.ps1 handles manually reviewed aliases/spelling from a private override file, still requiring a unique exact provider title/year. It does not assign guessed provider IDs. File names, alternate release titles, years and folder context are evidence; a short clip or unidentified TITLE01 is not assumed to be a full film.

Private before/after inventory, per-item original metadata, search candidates and result records are in the Windows .codex/private/homelab directory. They are not committed. Per-item JSON preserves metadata evidence; it is not an application-consistent database backup or a backup of replaced artwork. No backup framework was introduced.

## Verification

Test-JellyfinMovieMetadata.ps1 verifies that every original movie entry retains its ID/path and that repaired items have the expected TMDb ID, synopsis and poster. Live server OpenAPI was used to verify the search/apply/refresh API contracts. The first seven repaired Harry Potter entries were independently checked for completed metadata. One existing-match year discrepancy (Tokyo Drift) was reviewed: parent folder and matched movie are2006, filename says2011; retained the existing2006 match.

Final results and remaining review counts are recorded below. TV entries, duplicate video copies and sample clips are not removed by this metadata job.

Reviewed special cases include Disney adaptations with duplicate title/year provider results; the private override specifies the reviewed TMDb ID rather than selecting the first result. Disney's official title/release records were consulted for [Pocahontas](https://movies.disney.com/pocahontas), [The Hunchback of Notre Dame](https://movies.disney.com/the-hunchback-of-notre-dame), and [Hercules](https://movies.disney.com/hercules). Snow White's provider search uses1938 theatrical distribution, but [Disney records its premiere as December21,1937](https://movies.disney.com/snow-white-and-the-seven-dwarfs); the reviewed correction explicitly preserves the1937 premiere. Original filenames and collection context support, but cannot prove, the actual contents of every video; ambiguous items remain unresolved.

The broader existing-match audit compares title words with filenames/folder context and reviews suspicious year differences. Valid aliases (such as Bound by Honor/Blood In Blood Out) are retained. Explicit mismatches found include Melody Time, Snatch, Absolute Power parts, Lock Stock parts, Pale Rider part1, and gatvid-tgmd.avi. A45-second video-frame inspection of the latter confirmed The Great Mouse Detective rather than the unrelated prior metadata. Extracted frame is private; source video was read only. Correcting an existing provider ID requires the reviewed ExpectedOldTmdb guard. Split-file corrections append a part label to the Jellyfin display/sort title without renaming or joining files.

Three initial apply requests exceeded the45-second client timeout during a NAS load spike. Follow-up reads confirmed their expected provider IDs/year, synopsis, poster and unchanged paths, so these were recorded as completed rather than blindly retried. Final reviewed corrections use one worker after the automatic shards complete. No server/container restart was used.

## Completion results

Completed272 verified movie-entry repairs:264 previously withoutTMDb identification and8 incorrect existing matches. Each repaired entry now has its expected TMDb ID, reviewed year, synopsis and primary image. MissingTMDb entries fell916->652, missing synopsis787->530, missing year249->123. Counts include duplicate copies and split parts, not272 distinct film titles. All1555 original entry IDs and media paths remain unchanged; Jellyfin is healthy and its media mount remains read-only. No movie files moved, renamed, joined or deleted.

The private remaining-review.csv contains655 entries:627 TV episodes in Movies (616 season/episode filename patterns plus11 Planet Earth episodes),12 short clips/intros,8 sporting events, and8 videos requiring individual identification. Three short clips already have provider matches, so review-row count differs from652 remaining unmatched entries. These categories require classification/content review rather than blind movie metadata replacement. The existing-title audit retained valid aliases and left no known confidently correctable mismatch from that audit unresolved. This does not certify the identity of every video by viewing its full contents.

Final Test-JellyfinMovieMetadata.ps1 passed with0 verification issues across272 repaired entries, including release-year checks. Export-JellyfinMetadataReview.ps1 wrote the private review CSV. NAS load returned to about2.17 after the temporary spike. No broad NAS test suite, media rescan, downloads, scheduling, public networking change or backup deployment was performed. Private Windows inspection snapshots remain local; images/search results/library inventories are not committed. No push, merge, tag or release.
