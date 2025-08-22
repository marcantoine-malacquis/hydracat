# HydraCat Project References - READ THIS FIRST

alwaysApply: true

## Critical Rule

**Cursor AI MUST consult the reference files in `.cursor/rules/` before implementing anything**, including:

- Product features & requirements
- Technical architecture & dependencies  
- UI design & styling
- Database structure & Firebase rules
- Code organization & patterns

## Reference Files (all in `.cursor/rules/`)

- **`prd.md`** – Product Requirements (MVP vs Premium, user stories, success metrics)  
- **`tech_stack.md`** – Tech Stack & Project Structure  
- **`ui_guidelines.md`** – UI Design, colors, typography, accessibility  
- **`firestore_schema.md`** – Firestore collections, fields, indexes  
- **`firebase_CRUDrules.md`** – CRUD operations, offline sync, security rules  
- **`clarify.md`** – Code standards, naming, error handling, performance  

## Mandatory Process Before Coding

1. Check `prd.md` for feature requirements  
2. Check `tech_stack.md` for implementation approach  
3. Check `ui_guidelines.md` for UI/styling  
4. Check `firestore_schema.md` for database structure  
5. Check `firebase_CRUDrules.md` for data operations  
6. Apply standards from `clarify.md`  

**If ANY step is unclear, stop and ask clarifying questions.**

## Non-Negotiables

- Implement only PRD-specified features  
- Respect Free vs Premium distinctions  
- Follow UI, tech, and database rules exactly  
- Use approved libraries and Riverpod for state management  
- Maintain accessibility and design standards  

**Reference files are the single source of truth. Always follow them.**
