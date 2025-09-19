# Firebase Firestore Cost Optimization Guidelines

description: >
  Rules to ensure all Firebase code in this project is optimized to minimize
  Firestore reads, writes, and deletes. Follow these strictly to avoid unnecessary usage costs, especially for large collections and real-time queries.

alwaysApply: true
globs: ["**/*.dart"]

---

## Querying and Reading

- **Paginate large queries**  
  Always use `.limit()` and pagination (`startAfter`) when querying collections like `fluidSessions`. Never fetch entire collections unless absolutely required. Example: fetch 20 sessions at a time. Never fetch entire collections unless absolutely required.

- **Avoid unnecessary re-reads**  
  Cache static data (e.g., user profile, pet info, schedules) in memory or local storage (`shared_preferences` or SQLite). Refresh only if data changes.

- **Restrict real-time listeners**  
  Use `snapshots()` only for recent or actively changing data (e.g., latest 1–5 docs).  
  Never attach listeners to entire history collections (daily/weekly/monthly summaries or old sessions).

- **Filter precisely**  
  Always use `.where()` clauses to limit the number of documents returned from Firestore. Example: fluidSessions.where("petId", isEqualTo: currentPetId).limit(20)

- **No full-history fetch for analytics**  
  Do not query all session docs for analytics. Instead, read from pre-aggregated fluidSummaryDaily, fluidSummaryWeekly, or fluidSummaryMonthly docs. Example: reading 12 docs for a year instead of 365 sessions.

- **Enable offline persistence** 
Use Firestore’s built-in offline persistence so users can see cached data without triggering new reads every time the app opens.

- **Use indexes for multi-field queries**
If you query with multiple .where() filters (e.g., petId + dateTime), create composite indexes in Firebase Console. This avoids inefficient scans.
---

## Writes and Updates

- **Throttle frequent writes**  
  Avoid writing frequently changing fields like `lastUsedAt` on every app action.  
  Update at most once per app session or daily.

- **Batch writes**  
  When updating multiple docs, use `WriteBatch` or `runTransaction` to minimize write operations.

- **Avoid tiny frequent writes**  
  Combine small updates into a single batched operation whenever possible.
  Example: update totalVolume and streakCount together, not separately.

- **Error logging**   
Always handle failed writes with error logging (e.g., try/catch with Sentry or Firebase Crashlytics). Never silently drop failed operations.
---

## Data Modeling

- **Use summary documents for analytics**  
 Maintain pre-aggregated summaries for each pet:
Daily: fluidSummaryDaily/{YYYY-MM-DD} (e.g., 2025-08-15)
Weekly: fluidSummaryWeekly/{YYYY-W##} (e.g., 2025-W33)
Monthly: fluidSummaryMonthly/{YYYY-MM} (e.g., 2025-08)
Update these at the time of logging a fluidSession.
This way analytics queries only need a handful of docs instead of hundreds.

- **Denormalize when beneficial**  
  Store key fields (e.g., pet name) directly in frequently accessed docs like `fluidSessions` to avoid extra reads for related data.

---

## Monitoring

- **Track usage regularly**
  Monitor Firestore usage in the Firebase Console and set up Google Cloud budget alerts.
- **Audit queries**
 Regularly review queries to ensure no accidental "fetch all" patterns are introduced.
