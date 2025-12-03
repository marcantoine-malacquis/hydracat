
# HydraCat – Hydration Trend Specification  
### Version 1.0 — Multi‑Section Document

---

# 1. Algorithm Specification

## 1.1 Goal of the Feature
The Hydration Trend feature provides a simple, owner-friendly daily score (0–100) reflecting the cat’s estimated hydration stability. It is based on research-backed relationships between subcutaneous fluids, dietary moisture intake, symptom-driven losses, body weight, and CKD pathophysiology.

The score is **not a clinical measurement**. It is a **risk-adapted, trend-based model**.

---

## 1.2 Scientific Basis

### CKD Hydration Physiology
- CKD reduces concentrating ability → chronic polyuria → higher dehydration risk.
- Maintaining hydration improves quality of life and reduces crises.

### Dietary Water Intake (Buckley 2011)
- Wet food diets (~75% moisture) provide ~30 ml/kg/day.
- Dry diets fail to stimulate adequate voluntary drinking.

### Water Intake & Urine Dilution (Zanghi 2018)
- Increased drinking → lower USG and Uosm → improved hydration markers.

### Subcutaneous Fluids (ISFM)
- Common home therapy: 75–150 ml every 1–3 days.
- Provides a strong short-term hydration benefit lasting 12–24 hours.

---

## 1.3 Inputs

### Required Daily Inputs
- SubQ fluids given (Y/N, volume)
- Wet food eaten (%)
- Appetite (0–3 scale)
- Vomiting (0–3)
- Diarrhea (0–3)
- Energy/Fatigue (0–3)

### Optional Inputs
- Dehydration signs (tacky gums, sunken eyes, skin tenting)
- Body weight (weekly)

### Automatic Inputs
- CKD stage
- Time since last SubQ
- Rolling 3‑day window

---

## 1.4 Components of the Score

### Base Intake Component (0–40 pts)
Wet food moisture:
- 90–100% → +30  
- 60–89% → +20  
- 30–59% → +10  
- 1–29% → +5  
- 0% → 0  

Appetite modifier:
- Score 0 → +10  
- Score 1 → +5  
- Score 2 → +0  
- Score 3 → –5  

### SubQ Component (0–40 pts)
- Today: Volume ÷ 10 (max 40)
- Yesterday: (Volume ÷ 10) × 0.5
- > 48 hours: 0 pts

### Losses Component (max –30 pts)
Vomiting:
- 0 → 0  
- 1 → –10  
- 2 → –15  
- 3 → –20  

Diarrhea:
- 0 → 0  
- 1 → –5  
- 2 → –10  
- 3 → –15  

Energy/Fatigue:
- 0 → 0  
- 1 → –5  
- 2 → –10  
- 3 → –15  

Dehydration flags:
- tacky gums → –10  
- sunken eyes → –15  
- skin tenting → –20  

### Stability Component (–10 to +10)
Weight change (weekly):
- stable → +5  
- ↓1–3% → –5  
- ↓>3% → –10  

CKD stage:
- Stage 1 → +5  
- Stage 2 → +0  
- Stage 3 → –5  
- Stage 4 → –10  

---

## 1.5 Final Score Calculation

### Raw score:
```
RawScore = BaseIntake + SubQComponent - LossesComponent + StabilityComponent
```

Clamp to **0–100**.

### Smoothed score:
```
HydrationScoreToday = average(Score[t], Score[t–1], Score[t–2])
```

---

# 2. UI Specification

## 2.1 Graph

### X‑Axis:
- Daily points (7–14 days)

### Y‑Axis:
- Hydration Trend Score (0–100)
- Color zones:
  - **80–100** Stable (green)
  - **60–79** Borderline (yellow)
  - **<60** At Risk (orange/red)

### Data markers:
- SubQ day → droplet icon  
- Vomiting/diarrhea → warning icon  

---

## 2.2 Daily Summary Card

**Example layout:**

- Hydration Score: **82/100**  
- Trend arrow: ↑ improving / ↓ worsening  
- Highlight: “Hydration stable today.”  
- Icons for fluid given, food intake, symptoms  

---

## 2.3 Detail Screen

Sections:
1. **Today’s Score**
2. **Trend Graph (7–14 days)**
3. **Factors affecting today’s score**
4. **Recommendations** (non-medical guidance)

---

# 3. UX Copy

## 3.1 Explanations to Users

### Stable Hydration
“Your cat’s hydration has been consistent and within a healthy range.”

### Mild Risk
“Hydration is slightly lower than usual. Monitor appetite and symptoms.”

### High Risk
“Hydration appears low. If symptoms persist, contact your veterinarian.”

---

## 3.2 Onboarding Copy
“HydraCat estimates your cat’s daily hydration trends using data you log about fluids, food, and symptoms. This is not a medical measurement, but a helpful indicator of hydration stability.”

---

## 3.3 Disclaimer
“Hydration Trend is an estimate based on symptom and diet data. It is not a diagnostic tool. For concerns about dehydration, contact your vet.”

---

# 4. Future Extensions

- Litterbox urine‑output proxy  
- Smart water bowl integration  
- Personalized ML‑based scoring  
- Lab value import (USG, creatinine, BUN)

---

# End of File
