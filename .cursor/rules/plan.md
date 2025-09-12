---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Also, keep in mind the CRUD rules file to make sure to keep firebase costs to a minimum.

Please let me know if this makes sense or contradict itself, the prd or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.

Please add only the important informations to remember about what we implemented in this step for future reference in 



Actually I changed my mind and would like to add a screen dedicated to CKD related information right between the basic profile screen and the treatment setup screen. It would only get CKD related informations : diagnosis date, IRIS stage (side by side, highlighted on press button for the 4 stages), creatinine/BUN/SDMA value levels but I think it's important to have it to show that it really is a professional vet-developped app. It might also include a tool to evaluate the IRIS stage based on those values but this will be implemented later on if at all. This screen will be the same for every persona.


1. Add a new ckdMedicalInfo step between petBasics and treatmentSetup and update all step indices accordingly?
2. Maybe make the progress indicator dynamically calculate total steps from the
  OnboardingStepType enum. Maybe this could be useful so we can reuse this progress indicator elsewhere in the app and be easily adapted to other situations. Please use the best strategy so we can easily reuse this progress indicator.
3. Please do what makes the most sense knowing we will use this labvalues for analysis and they will be updated every 6-12 month
4. Please suggest what would make the msot sense in this situation and the industry standard way of doing it
5. a) Create lab value validation that's purely structural (non-null, positive numbers) without medical interpretation. Creatinine/BUN can vary and go extremely high for CKD cats so validation would be tough. c) Add bloodwork date validation to ensure it's not in the future. No need to worry about the pet age.
6. a)Use similar TextFormField widgets for lab values with decimal number input
  validation (up to 2 decimals) c) do what you think makes the most sense in this project
7. Follow the same pattern as the welcome screen with a skip button in the navigation area. If the screen is skipped, no CKD medical data should be saved. Users will as usual have the option to add it later via the Profile screen.
8. I don't know if this is the place to achieve it, but I would like to know how many of my users are in each IRIS category. But there might be an easier way to achieve this than screen analytics tracking. Maybe database analysis would make more sense. Don't include skip events and completion timing, i don't care about those.
Please let me know if this makes sense or contradict itself, the prd or existing code. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.