---
description: Ask clarifying questions
    - "**/*"

alwaysApply: false
---

Please create a detailed plan of how you will achieve and implement this step.
Before you create the plan, please ask any and all questions you have in order to provide the most robust solution to handle edge cases and/or additional context that you might need to feel confident in proceeding with the implementation. When you do use clarifying questions, please do not use bullet points but rather letters within each numbered question if number requires bullet points. Before you ask me questions, please already have a look at all the existing files you would need to already have the context, use existing systems, ensure coherence and in case you already find the answer to your questions. Keep in mind that I want to have the best suited solution for my project while being in line with industry standards as much as possible. Also, keep in mind the CRUD rules file to make sure to keep firebase costs to a minimum.

Please let me know if this makes sense or contradict itself, the prd or existing code. Coherence is extremely important. Let's me know if you need any more clarifications to feel confident in proceeding with the implementation.

Please update and add only the important informations to remember about what we implemented in this step for future reference in 


1. a) Nested into a parent /onboarding route with sub-routes
b) Please do what makes the most sense for my project, have a clean code structure and a solution that is future-proof and industry standard.
2. a) Authenticated users who have not completed onboarding should be automatically redirected to the onboarding flow. If, for example, they lost connection or they closed the app, but users who skipped the onboarding willingly, so with the skip button, should not be reverted directly to the onboarding flow. They should be allowed to go to the home screen where they will have a limited option of exploration of the app into the different navigation icons to discover a bit what the apps look like, but the usage will be very limited.
b) Yes, exactly. So users who willingly skip the onboarding using the skip button will have access to the main app features with very limited functionality. 
c) If a user is in the middle of onboarding, but closes and reopens the app, they should resume from their last step. 
3. a) Only the UI back button in the onboarding screen. 
b) Their later progress should be preserved.
4. I am not familiar with the deep links and deep linking. This is the first time I hear this. Can you please provide an explanation related to your questions about what it would bring to my app and user experience and your advice if I should bother at the moment already about deep links?  
5. a) Authentication is mandatory to use the app. Can you please point to me where you may have found that authentication is not mandatory?
b) Then the onboarding goes back to the first onboarding screen, but the data that is already saved should be already inputted as it was when it was saved.
6. a) Yes, I want slide animations between onboarding screens. 
b) We will probably reuse this slide animation code if. So make it future proof for the rest of the app if possible. 

1. Do what you think makes the most sense for my project and what is industry standard.
2. They will see the same home screen UI With limited functionality. 
3. So they can navigate between the different screens using the navigation bar. They can have access to particularly the educational content in the learn section. But every other screen will pretty much be blank for them with an illustration that I will put later telling them that they need to complete the onboarding to get access to all the functionality. Especially if they click on the logging FAB button in the middle of the navigation bar, they should be redirected automatically to the start of the onboarding. 














1. a) So I think for better UX, the user should have the option to add a medication (+ button) to a list of medication. When the user press the + button a pop-up appears to input the name of the medication (string) and unit (rotating wheel. it should support pill, drops, sachets, injections, capsules, micrograms, miligrams, ampoules, mililiters, tablespoon, teaspoon, portion. In alphabetical order). There will be a "Next" button at the bottom of this popup that leads to another popup to select the frequency with a list to select either once daily, twice daily, thrice daily, every other day, every 3 days (specific to mirtazapine). I will expand this list later. There will be a "Next" button at the bottom of this popup that leads to another popup to select the reminder time.On this "set reminder" popup, there will be time of day selection (rotating wheel like it is standard on IPhone). The number of time of day selections will depend on the number of intake per day previously selected (First intake, Second intake, Third intake). At the bottom of this "set reminder" popup there will be a "Save" button that will save the data locally and close the popup to go back to the medication list. On this list, the user will be able to see the name of the medication and a summary (for example: "One pill daily" or "1/2 pill twice a day"). At the bottom of the screen, there will be a "Next" button that leads to the Completion screen
b) For fluid therapy, the user should input all on the same screen (scrollable if needed) : frequency, volume per administration, prefered location on the cat (rotating wheel to select among shoulder blade level - left, shoulder blade level - right, hipbones level - left, hipbones level - right), needle gauge.
At the bottom of the screen, there will be a "Next" button that leads to the Completion screen
c) for medication and fluid persona, the user will be guided first on the medications screens then on the fluid screen
2.a) let's create separate treatment-specific data classes
b) yes, data should only be persisted to Firebase on final completion
3. a) "You can update you schedules anytime in the Profile section"
b) subtle
4. a) no, there might be a misunderstanding. Each of those screens will have a "Next" button that allow to save data only locally and move to the next screen. Data will be stored locally between each screen here. There will be a final "Finish" button on the Completion screen that will be the only one allowing to write the data to firebase, there will be no comeback option after pressing this finish button as the user will be guided to the home screen automatically. The user will have the option to modify the data afterwards in the Profile section but will not have access to the initial onboarding anymore.
b) the data will be filled and saved one screen at a time. For medication, it will also be saved at the final popup when adding a new medication.
5. a) users can go back anytime. When changing persona, data should NOT be cleared. The most frequent case would be someone going from medication only or fluid only to medication & fluid, so they will still need the previous data.
b) not that I can think of, let me know if you think something would be an invaluable idea
6. a) average fluid volumes chosen would be interesting but nothing more for now
b) no










For each medication, we will need name, frequency and dosage (pill, drops, sachets, injections, capsules, mg, mL, ampoules, mL, etc... It should also support 1/4, 1/2, etc...). There will be one time selection if it's once per day or two time selections if it is twice a day. Each medication in the list should be collapsable to reveal the informations inside. For each medication there will be a "set a reminder" button that on press will disappear and leave place to a time of day selection (rotating wheel like it is standard on IPhone). There will also be a small "Note" section in case any specific information need 