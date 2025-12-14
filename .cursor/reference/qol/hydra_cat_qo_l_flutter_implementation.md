# HydraCAT QoL – Flutter Implementation Specification

## Feature Overview

HydraCAT QoL is a longitudinal quality of life tracking feature composed of:
1. A short owner questionnaire (14 items)
2. Automated domain and overall scoring
3. Trend detection and visualization
4. Shareable longitudinal summaries

---

## Questionnaire Structure

- **Total items:** 14
- **Domains:** 5
- **Recall period:** Past 7 days
- **Estimated completion time:** 2–3 minutes

Each item is presented on a **single screen** with one‑tap selection and automatic progression.

---

## Answer Scale (All Items)

Each question uses the same 5 options:

| Score | Label |
|------|------|
| 4 | Always / Very much / As usual or better |
| 3 | Often |
| 2 | Sometimes |
| 1 | Rarely |
| 0 | Never / Much worse than usual |

Additional option (non‑scored):
- **Not sure / Unable to observe this week**

---

## Reverse‑Scored Items

Some items describe negative experiences (e.g., stress, resistance to treatment).

Implementation rules:
- UI always visually implies **right = better**
- Reverse scoring handled only in logic layer
- Unit tests required for every reverse‑scored item

---

## Data Model

```dart
class QoLQuestion {
  final String id;
  final String domain; // vitality, comfort, emotional, appetite, treatment
  final String text;
  final bool reverseScored;
}
```

```dart
class QoLResponse {
  final String questionId;
  final int? score; // null = not sure
}
```

---

## Scoring Logic

### Domain Score
```text
Domain Score = mean(score_i) for all answered items in domain
```

- Exclude null responses
- Track answered/total count per domain

### Overall Score
```text
Overall QoL = mean(domain scores)
```

Domains are equally weighted.

---

## Data Quality Indicator

For each domain:
- Display “X / Y items answered”
- If <50% items answered, flag domain as **low confidence**

---

## Trend Engine

### Stored Values
- Date
- Domain scores
- Overall score

### Computed Metrics
- Δ since last assessment (per domain + overall)
- Rolling 4–8 assessment trend
- Stability indicator: Stable / Improving / Declining

### Notable Change Detection (Heuristic)
- Drop ≥15 points in a domain
- Sustained across ≥2 consecutive assessments

> These are **product heuristics**, not clinical alerts.

---

## Score Bands (Tracking Labels)

| Overall Score | Band |
|--------------|------|
| ≥80 | Very good |
| 60–79 | Good |
| 40–59 | Fair |
| <40 | Low |

Displayed as **tracking bands**, always accompanied by trend context.

---

## Interpretation Copy Rules

- No diagnostic language
- No disease or lab references
- Action framed as observation and discussion

**Example:**
> “Your cat’s energy and comfort scores have been lower than their recent baseline for two weeks. You may want to discuss recent changes, appetite, hydration, and comfort with your veterinarian.”

---

## Visualization

### Summary Screen
- Radar chart (5 domains)
- Overall score + band
- Change vs last assessment

### Trend Screen (Premium)
- Line charts per domain
- Overall QoL trajectory
- Event markers (medication or fluid changes)

---

## Sharing with Veterinarian

Exportable summary includes:
- Last 8–12 assessments
- Domain‑specific trends
- Overall trajectory
- Optional raw item responses

PDF / image export supported.

---

## Safety & Disclaimers

Persistent footer text:
> “HydraCAT QoL tracks quality of life over time and does not replace veterinary care. Contact your veterinarian if you are concerned about your cat’s health.”

---

## Monetization Logic

Free tier:
- Single assessment
- Current snapshot only

Premium tier:
- Unlimited history
- Trend analysis
- Notable change detection
- Vet‑ready export

