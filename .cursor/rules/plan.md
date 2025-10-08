---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

## 📋 Implementation Guidelines

### Analysis & Planning
- After analysing the situation and looking at the relevant code, ultrathink to come up with the most appropriate plan
- Ask clarifying questions with lettered sub-points (not bullet points) for numbered questions
- Review existing files, previous implementations, PRD, CRUD rules, and relevant code before asking questions
- Suggest recommended solutions for each question
- Follow Firebase and Flutter best practices, use built-in solutions over custom ones
- Minimize Firebase costs per CRUD rules (.cursor/rules/firebase_CRUDrules.md)
- Note: Database backward compatibility not required (regularly deleted for testing)

### Quality Checks
- Verify coherence with PRD (prd.md), CRUD rules, and existing code
- Follow app development best practices and industry standards
- After implementation, check and fix linting issues
- Update logging_plan.md with important information for future reference (keep concise, step format)

### Testing Protocol
- **Do NOT** run the app yourself to test
- Tell me when testing is needed - I will run it manually
- I will test only after linting issues are fixed

### Recent Implementation Notes
**Phase 6 - Cache Integration (Completed):**
- ✅ `LoggingService` now injects `SummaryCacheService` for 0-read duplicate detection
- ✅ Quick-log validation uses cached summary (no Firestore reads)
- ✅ Pattern: `LoggingService(cacheService)` via provider dependency injection