# HydraCAT QoL – TL;DR for Flutter Implementation

## What This Feature Is

A **short, owner‑reported questionnaire** that tracks a CKD cat’s quality of life over time.

It focuses on **trends, not diagnosis**, and is designed to support conversations with veterinarians.

---

## Core Design Principles

- Longitudinal > snapshot
- Observable behaviors only
- No diagnostic claims
- Trend‑first interpretation
- Premium value through insight, not complexity

---

## Questionnaire

- 14 questions
- 5 domains: Vitality, Comfort, Emotional, Appetite, Treatment Burden
- Recall period: past 7 days
- Completion time: ~2–3 minutes

All questions use the same 0–4 scale + “Not sure”.

---

## Scoring

- Higher score = better QoL
- Domain score = mean of answered items
- Overall score = mean of 5 domains
- Domains equally weighted

Missing answers are excluded, not imputed.

---

## What Users See

### After One Assessment
- Radar chart
- Overall score + tracking band
- Clear explanation that this is a baseline

### Over Time (Premium)
- Domain trend lines
- Change vs last assessment
- Stability / improvement / decline indicators

---

## Interpretation Rules

- No diagnoses
- No lab references
- No emergency claims based on score

Copy always emphasizes:
> “Compared to your cat’s recent baseline…”

---

## Safety

QoL scores never trigger emergency advice.

Red‑flag education (not eating, repeated vomiting, collapse, breathing difficulty) lives in a **separate safety section**.

---

## Why This Is a Flagship Feature

- Emotionally meaningful to owners
- Clinically credible without overreach
- Generates high‑value longitudinal data
- Naturally supports premium upgrades
- Vet‑friendly without being vet‑only

---

## One‑Sentence Pitch

> “HydraCAT QoL helps you see how your cat is really doing over time — not just today, and not just on paper.”

