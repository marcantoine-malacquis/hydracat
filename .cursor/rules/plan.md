---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---
After analysing the situation and looking at the relevant code, please come up with the most appropriate plan, following best practices, to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

After analysing the situation and looking at the relevant code, please ultrathink to come up with the most appropriate plan to fix this issue. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please ultrathink to come up with the most appropriate plan to achieve this. After analysing the situation and looking at the relevant code, please ask me any question you would need to feel confident about solving the issues. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards and app development best practices as much as possible. Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions. Also, keep in mind the CRUD rules file (.cursor/rules/firebase_CRUDrules.md) to make sure to keep firebase costs to a minimum. Regarding database, I don't need to worry about backward compatibility since I will regularily delete the database anyway for testing. After implementation, don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 

Please follow Firebase and Flutter best practices and use built-in solutions whenever possible instead of more complex custom solutions.

Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

Here is a conversation i had about those questions. Please review it and let me know what you agree with and what you would disagree with.


Let's fix the issue ... as documented in @onboarding_code_review_report.md. Please have a look at the relevant files and create the best plan to fix the issue. 



1. let's omit it from the session model for now. I might add it in the future but not now.
2. we probably should make them into double for easier adherence calculations but actually we should also store targetdosage as a double as well and use an helper method to turn the string input (like "1/2", "2.5") as a double and only store the double instead of the string. Please implement this.
3. a) yes, store as string as well
b) yes, let's also strore the strenght fields as well. Although would it be possible to only store customMedicationStrengthUnit in the session if it is actually used ? I suspect the vast majority of user will use preexisting medicationStrengthUnit so I should not store numerous null customMedicationStrengthUnit.
4. Let's not worry about what the firestore schema draft says and focus on the current reality. If we already have a FluidLocation enum, we should be coherent and store it like that as well. No need to use confusing string.
5. I think we should use a UUID with a factory constructor. Flutter has a UUID package/dependency https://pub.dev/packages/uuid. Yes, the ID should be required in the constructor (every session always has an ID from creation). We could also use a UUID validation helper if you think this would be best practice.
6. Let's not worry about what the firestore schema draft says. Let's use simply notes for both model and firestore.
7. Let's do c) Use required DateTime set client-side, with server timestamp confirmation on sync. Let's also enhanced the firestore scheme: fluidSessions/{sessionId}
  ├── dateTime: Timestamp       // Medical: treatment time
  ├── volumeGiven: number
  ├── createdAt: Timestamp      // Audit: client logging time
  ├── syncedAt: Timestamp       // Sync: server confirmation time
  └── updatedAt: Timestamp      // Modification: last edit time
Implementation Checklist:
 createdAt: Required DateTime, set with DateTime.now() at creation
 syncedAt: Optional DateTime?, set by FieldValue.serverTimestamp() on write
 updatedAt: Optional DateTime?, set by FieldValue.serverTimestamp() on modification
 dateTime: Required DateTime, user-selected treatment time
 All timestamps stored as Firestore Timestamp type
 Helper methods for sync status checking
8. Use Option C: Hybrid Validation
Implementation Checklist:
 Model Layer: Structural validation (validate(), isValid, validationError)
Required fields, data types, ranges, enum values, basic constraints
Synchronous, no external dependencies
Returns user-friendly error messages
 Service Layer: Business logic validation
Medical appropriateness, duplicate detection, schedule compliance
Asynchronous, accesses repositories
Returns structured warnings/errors with severity levels
Clear Separation: Model = "Is this data structurally sound?" | Service = "Is this medically appropriate?" 
Please absolutely look at already existing validation protocols in the app to find what should be appropriate. Ask me if you have any question.Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence and app development best practices is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.

yes, include the preparatory updates (1.1a) in the Step 1.1 implementation plan
a) let's do it as a preparatory step before we start b) yes let's create a DosageUtils class in lib/core/utils/ c) At the input widget level - Convert string → double immediately with validation.
d)Yes, add uuid: ^4.5.1 to the pubspec.yaml dependencies
e)Let's include all 4 timestamps : fluidSessions/{sessionId}
  ├── dateTime: Timestamp       // Medical: treatment time
  ├── volumeGiven: number
  ├── createdAt: Timestamp      // Audit: client logging time
  ├── syncedAt: Timestamp       // Sync: server confirmation time
  └── updatedAt: Timestamp      // Modification: last edit time
Please let me know if this makes sense or contradict itself, the prd, the CRUD rules or existing code. Coherence and app development best practices are extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation. Don't try to run the app yourself to test. Just tell me when it's needed and I will run it manually to do the testing myself.



