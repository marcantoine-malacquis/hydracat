
# HydraCat — Symptom Tracking & Trend Analysis (Full Specification)

This document describes the complete specifications for the updated Symptom Tracking & Trend
Analysis system used in HydraCat. It includes user-facing input rules, internal scoring logic,
visualization rules, data storage, analytics behavior, and UI interaction guidelines.

---

## 1. Overview

HydraCat uses a **Hybrid Symptom Scoring Model** to allow owners to enter accurate,
symptom-specific information while the system internally converts all symptoms into a unified
severity score for analytics and charting.

### Architecture (2 Layers)

1. **User-Facing Input:**  
   Tailored input per symptom (e.g., number of vomiting episodes, appetite fraction).

2. **Unified Severity Score (0–3):**  
   All symptoms are normalized to the same scale for trend charts and analytics.

This creates medical accuracy *and* visual consistency.

---

## 2. Symptoms Tracked
HydraCat tracks:
- Vomiting
- Diarrhea
- Constipation
- Suppressed Appetite
- Injection Site Reaction
- Energy

These feed into:
- Daily stacked symptom bar charts
- 30-day history (free)
- Unlimited historical analytics (premium)
- Correlation analytics (premium)
- Veterinary PDF reports (premium)

---

## 3. Data Model

```json
{
  "date": "YYYY-MM-DD",
  "symptomType": "vomiting | diarrhea | constipation | appetite | injectionSiteReaction",
  "rawValue": <number|string>,
  "severityScore": <0–3>,
  "notes": "<optional>",
  "timestamp": "<auto>"
}
```

---

## 4. User Input & Internal Severity Conversion

Below are the user-facing inputs and the internal 0–3 severity conversions.

---

### 4.1 Vomiting

**User Input:**  
“How many vomiting episodes today?” (0–10+)

**Severity Conversion (0–3):**

| Episodes | Severity |
|----------|----------|
| 0 | 0 |
| 1 | 1 |
| 2 | 2 |
| ≥3 | 3 |

**Raw Value Stored:** Number.

---

### 4.2 Diarrhea

**User Input:** Stool quality selector:
- Normal
- Soft
- Watery / liquid

**Severity Conversion:**

| Descriptor | Severity |
|------------|----------|
| Normal | 0 |
| Soft | 1 |
| Watery / liquid | 3 |

---

### 4.3 Constipation

**User Input** Straining:
 
- Normal stooling  
- Mild straining  
- No stool  
- Painful/crying  

**Severity Conversion:**

| Descriptor | Severity |
|------|----------|
| Normal | 0 |
| Mild straining  | 1 |
| No stool | 2 |
| Painful/crying  | 3 |

---

### 4.4 Suppressed Appetite

Matches HydraCat’s appetite scoring system, modified to 0–3:

**User Input:**  
- All  
- ¾  
- ½  
- ¼  
- Nothing

**Severity Conversion (simplified to 0–3):**

| Appetite | Severity |
|----------|----------|
| All | 0 |
| ¾ | 1 |
| ½ | 2 |
| ≤ 1/4 (¼ or Nothing) | 3 |

(The system merges ¼ and "Nothing" into severity 3 for simplicity.)

---

### 4.5 Injection Site Reaction

**User Input:**  
- None  
- Mild swelling  
- Visible swelling  
- Red & painful  

**Severity Conversion:**

| Reaction | Severity |
|----------|----------|
| None | 0 |
| Mild swelling | 1 |
| Visible swelling | 2 |
| Red & painful | 3 |

---

### 4.6 Energy

**User Input:** Overall energy level:
- Normal energy
- Slightly reduced energy
- Low energy
- Very low energy

**Severity Conversion:**

| Descriptor | Severity |
|-----------|----------|
| Normal energy | 0 |
| Slightly reduced energy | 1 |
| Low energy | 2 |
| Very low energy | 3 |

---

## 5. Unified Severity Model

All symptoms use **0–3** severity.

No normalization is needed for appetite anymore because its scale is now 0–3.

---

## 6. Trend Visualization

### 6.1 Week view

- Each day = 1 bar.
- Each symptom = a colored segment based on severity 0–3.
- Tap segment → tooltip displays:
  - Severity
  - True raw input (e.g., "3 vomiting episodes", "¼ ration eaten")
  - User notes (if any)

---

### 6.2 Month view
- 30/31 thin stacked bars.
- Summary table beneath:
  - Raw values
  - Severity score
  - Notes

---

### 6.3 Year view
- 1 stacked bar per month


---
**optional** ### 6.4 Unlimited Historical Trends (Premium)
- Long-term line graphs
- Symptom heatmaps
- Symptom correlation analysis with:
  - Weight
  - Hydration trend
  - Appetite
  - Fluid therapy sessions
  - Medications
- Exportable to PDF

---

## 7. Data Storage and Offline Behavior

- One entry per symptom per day.
- Firestore offline persistence ensures local caching.
- Last-write-wins conflict resolution.
- Local caching for charts (SharedPreferences).

---

## 8. UI & UX Specifications

### 8.1 Daily Check-In Flow
1. "Any symptoms today?"  
2. User selects symptoms that occurred  
3. For each selected symptom, the tailored input UI appears  
4. User confirms the day  
5. Data saved + severity score automatically computed

---

### 8.2 Drill-Down View
Stay Tapped on any chart day → shows:
- All symptoms recorded
- Raw values
- Severity values
- Notes

---

**future enhancement** ### 8.3 Educational Integration
Each symptom UI includes a small link:
“Why track this?” → Opens the relevant educational module.

---

**future enhancement** ## 9. Safety & Soft Warnings

HydraCat provides neutral, non-diagnostic messages for severe or persistent symptoms.

Examples:
- Vomiting ≥3 episodes for 2 days  
- Appetite severity 3 (≤1/4 of ration) for >24 hours  
- Injection site reaction severity ≥2  

Messages are informational and non-medical.

---

## 10. Developer Implementation Notes

### 10.1 Conversion Logic

Implement with a converter:

```dart
int getSeverityScore(String symptom, dynamic raw);
```

### 10.2 Caching Strategy
- Cache recent data locally for instant chart updates.
- Recompute severity on entry or edit.

### 10.3 PDF Export
Premium veterinary reports include:
- Severity chart
- Raw symptom table
- Notes
- Timeline view

---

## 11. Benefits

### For Users
- Intuitive symptom input  
- No confusing mixed-unit charts  
- Medically meaningful data  
- Better preparation for veterinary visits  

### For HydraCat
- Clean analytics  
- Consistent charting  
- Supports premium features  
- Research-grade structured data  

---

