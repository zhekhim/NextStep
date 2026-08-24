# UI Design Specification for Codex

## 1. Purpose

This document defines the visual design, layout rules, UI behavior, responsive behavior, and screen-level requirements for the Flutter mobile application.

Use this file together with:

- `AGENTS.md`
- `NextStep_Project_Specification.md`

This document defines **how the application should look and behave visually**.

The application has four main modules:

1. Student Profile & Skill Portfolio
2. Industry & Career Intelligence
3. Career Assessment & Recommendation
4. Career Goal & Readiness Intelligence

The application should feel like one connected product rather than four separate apps.

## 2. Important Dynamic Data Rule

Any names, numbers, salaries, percentages, dates, universities, skills, locations, career names, progress values, goals, and other examples in this document are **sample UI content only**.

Do not hard-code these examples into final production logic.

Examples such as:

- `Alex`
- `Data Analyst`
- `RM3,800`
- `72.5%`
- `3 / 5 skills satisfied`
- `Penang`
- `Kuala Lumpur`
- `2027`
- `Power BI`
- `25 August`

must be treated as placeholder/demo values.

In the real application, UI content must be populated dynamically from the current user's data, repositories, local database, Supabase, government API data, or calculated application state.

Only use hard-coded sample values temporarily when building an initial UI prototype, creating mock data before backend integration, or when explicitly instructed.

When mock data is used, keep it isolated and easy to replace later.

---

## 3. Design Direction

Use a dark, technical, professional mobile design resembling a modern developer-tool or technical dashboard adapted for a career-development application.

### Color Palette

| Purpose | Color |
|---|---|
| Main background | `#0F0F0F` |
| Deep/recessed surfaces | `#000000` |
| Main card surface | `#181818` |
| Elevated card/input surface | `#222222` |
| Strong surface | `#2A2A2A` |
| Primary accent | `#0007CD` |
| Active blue | `#0005A3` |
| Blue glow/highlight | `#1A26FF` |
| Primary text | `#FFFFFF` |
| Secondary text | `#A8A8A8` |
| Muted text | `#888888` |
| Disabled text | `#666666` |
| Divider | `#222222` |
| Success | `#33D17A` |
| Error/destructive | `#FF4D4D` |

Electric blue should be the dominant accent and should mainly be used for primary actions, selected navigation, progress indicators, selected states, important highlights, and focus states.

Avoid unnecessary extra colors.

### Avoid

- Excessive gradients
- Heavy shadows
- Bright colorful backgrounds
- Cartoon illustrations
- Glassmorphism
- Excessive pill-shaped controls
- Consumer social-media styling
- Decorative effects without a functional purpose

Use surface brightness, borders, spacing, and typography to create hierarchy.

---

## 4. Typography

Use `Inter` when available.

Recommended hierarchy:

| Element | Size | Weight |
|---|---:|---:|
| Large page heading | 28–32px | 500 |
| Section heading | 20–24px | 500 |
| Card title | 16–18px | 600 |
| Body text | 14–16px | 400 |
| Supporting text | 12–14px | 400 |
| Button text | 14px | 500 |
| Small label | 11–12px | 500 |

Keep typography clean with strong contrast between white primary text and gray supporting text.

---

## 5. Spacing and Component Style

Use:

- `16px` horizontal page padding
- `16–24px` spacing between major cards
- `8–12px` spacing between tightly related elements
- Generous whitespace
- Scrollable layouts for long screens
- `8px` radius for buttons and inputs
- `12px` radius for smaller cards
- `16px` radius for major cards
- `40–44px` minimum touch target
- Thin `#222222` dividers
- Simple outline icons

Do not overcrowd screens.

For long forms, use scrolling instead of squeezing all fields into one viewport.

---

## 6. Buttons

### Primary
- Electric blue background
- White text
- 8px radius

### Secondary
- `#222222` background
- White text
- 8px radius

### Outline
- Transparent background
- `#333333` border
- White text

### Text
- No filled background
- Gray or white text

### Destructive
Use red only for destructive actions such as delete operations.

---

## 7. Inputs

Inputs should use:

- `#181818` or `#222222`
- 8px radius
- White entered text
- Gray placeholder text
- Blue focus state
- Clear validation/error state

Show field-specific errors directly below the relevant field when practical.

---

## 8. Cards

Cards should use:

- `#181818` surface
- 12–16px radius
- No heavy shadow
- Clear spacing
- Subtle borders/dividers where useful
- Strong information hierarchy

Avoid putting every tiny piece of information into a separate card.

---

## 9. Global Navigation

Use a consistent bottom navigation bar with five destinations:

1. Home
2. Careers
3. Assessment
4. Goals
5. Profile

Use simple outline icons.

Selected item:
- Electric blue

Inactive item:
- Muted gray

The Home dashboard acts as the central overview.

Where appropriate, the top bar may contain:

- App name/logo
- Notification icon
- Profile/avatar

---

## 10. Home Dashboard

The Home screen should dynamically reflect the signed-in user's actual data.

### Welcome Section

Prototype example:
`Good evening, Alex`

Real behavior:
- Greeting may change based on time
- User name comes from the current profile
- Use a suitable fallback if unavailable

Supporting text:
`Continue building your career readiness.`

### Career Readiness Card

Show dynamically:
- Career readiness label
- Current calculated readiness percentage
- Progress visualization
- Status label

Example prototype values such as `72.5%` or `Good Progress` must not be hard-coded.

### Current Career Goal

Show the user's actual current goal:

- Target career
- Target industry
- Preferred state
- Graduation year

Action:
`View Goal`

If no goal exists, show a useful empty state and CTA instead of fake data.

### Skill Overview

Show dynamically:
- Skill-match result
- Number of required skills satisfied
- Relevant skill rows/chips

Sample skills such as Python, SQL, Power BI, and Statistics are only examples.

### Assessment Overview

Show whether the user has completed an assessment during the current session and provide a direct action, e.g.:

`Discover careers that match your interests.`

### Recommended Career

When assessment results are available, show the highest-ranked career and its calculated match percentage.

If no assessment has been completed, show an appropriate prompt instead of a fake recommendation.

### Quick Actions

- Explore Careers
- Add Skill
- Take Assessment
- View Readiness

The dashboard should feel like a compact career command center.

---

## 11. Module 1 — Student Profile & Skill Portfolio

### Profile Screen

Display dynamic profile information:

- Profile avatar
- Student name
- Email
- University
- Major
- Year of Study
- Preferred Employment State

Actions:

- Edit Profile
- Manage Skills
- Delete Account

The design should feel like a professional career profile, not a social-media profile.

### Edit Profile

Fields:

- Full Name
- Email
- University
- Major
- Year of Study
- Preferred Employment State

Primary:
`Save Changes`

Secondary:
`Cancel`

Validation examples:

- `Please enter a valid email address.`
- `This field is required.`

When editing, populate existing values dynamically.

### My Skills

Header:
`My Skills`

Include:

- Search field: `Search skills...`
- Category filter: `All Categories`
- Dynamic skill list
- `+ Add Skill`

Each skill displays:

- Skill name
- Skill level
- Category
- Edit action
- Delete action

Do not hard-code sample skills.

If no skills exist:
`No skills added yet.`

### Add / Edit Skill

Fields:

- Skill Name
- Skill Category
- Skill Level

Levels:

- Beginner
- Intermediate
- Advanced

Primary:
`Save Skill`

Validation:

- `Skill cannot be empty.`
- `{skillName} is already in your skill portfolio.`
- `Please select a valid skill level.`

Delete confirmation:

Title:
`Delete Skill?`

Message:
`Are you sure you want to remove {skillName} from your skill portfolio?`

Buttons:

- Cancel
- Delete

---

## 12. Module 2 — Industry & Career Intelligence

### Career Explorer

Header:
`Explore Careers`

Include:

- Search
- Industry filter
- State filter
- Salary filter when supported
- Demand filter when supported

Career cards may show:

- Career title
- Industry
- Median graduate salary
- Industry growth
- Employment demand
- Required skills
- Government Data Source label

All values must come from actual dataset/API/repository data.

Do not invent unavailable statistics.

Actions:

- View Career
- Compare

### Career Detail

Display dynamic:

- Career title
- Industry
- Median salary when available
- Industry growth when available
- Employment demand when available
- Required skills
- Career insights
- Government Data Source

Use simple charts/cards only for supported data.

Actions:

- Add to Shortlist
- Compare Career

### Career Comparison

Allow comparison of 2–3 careers selected by the user.

Compare:

- Industry
- Median Salary
- Industry Growth
- Employment Demand
- Required Skills
- Preferred State where relevant

Use a mobile-friendly comparison layout.

Do not hard-code which careers are compared.

### Career Shortlist

Header:
`My Career Shortlist`

Each item may show:

- Career
- Priority
- Preferred State
- Personal Note

Actions:

- Edit
- Delete
- View Career

Priority values:

- High
- Medium
- Low

Include:
`+ Add Career`

If no items exist, show a proper empty state.

### Opportunities Near Me

Header:
`Opportunities Near Me`

Show current or manually selected location dynamically.

Display nearby industry/career insights based on available data.

Do not hard-code Kuala Lumpur or any state.

Provide:
`Change Location`

If location permission is unavailable or denied, allow manual state selection.

---

## 13. Module 3 — Career Assessment & Recommendation

### Assessment Introduction

Header:
`Assessment`

Show a centered introduction containing:

- Assessment icon
- `Career Assessment` title
- Short explanation of its purpose
- Number of questions
- Approximate completion time

Primary action:
`Start Assessment`

### Assessment Question

Show one question at a time.

At the top, show:

- `Question {current} of {total}`
- Linear progress indicator

The question card contains:

- Question text
- Five selectable answers numbered 1 to 5

Answer labels:

- Strongly Disagree
- Disagree
- Neutral
- Agree
- Strongly Agree

Clearly highlight the selected answer with the primary color and a check icon.

Navigation actions:

- `Previous`
- `Next`
- `Submit` on the final question

Validation:

- `Please select an answer before continuing.`
- `Please answer all questions before submitting.`

### Assessment Results

Show:

- `Your Career Profile` heading
- All six dimension scores in ranked order
- Percentage for each dimension
- The user's three strongest areas
- Top five career matches

Each career match card shows:

- Rank
- Career name
- Match percentage
- `Explore Career` action

After opening a recommended career, the Career Detail screen includes:
`Set This Career as Goal`

If the user already has a different goal, ask for confirmation before replacing it. Preserve the existing optional goal details, set the selected career as the active goal, and navigate directly to the Career Goal page after a successful replacement. Show clear success and failure feedback.

Primary action:
`Retake Assessment`

### Loading, Empty, and Error States

Questions loading:
`Loading assessment questions...`

Questions unavailable:
`No assessment questions available.`

Question load failure:
`Unable to load assessment questions.`

Matches loading:
`Generating career matches...`

No matches:
`No career matches are currently available.`

Match failure:
`Unable to generate career matches.`

Error states should provide `Retry` where the operation can be attempted again.

### Responsive Behaviour

Use a scrollable layout for questions and results. Long question or career text must wrap without clipping. Buttons must remain large enough for comfortable mobile use.

---

## 14. Module 4 — Career Goal & Readiness Intelligence

This module should visually communicate transparent rule-based and data-driven calculations.

Do not present deterministic calculations as vague AI.

### Career Goal

Header:
`My Career Goal`

Display actual:

- Target Career
- Target Industry
- Preferred State
- Target Graduation
- Expected Salary
- Status

Actions:

- Edit Goal
- Delete Goal

If no goal exists:

`Set Your Career Goal`

CTA:
`Create Career Goal`

### Create / Edit Career Goal

Fields:

- Target Career
- Target Industry
- Preferred State
- Target Graduation
- Expected Salary
- Status

Status:

- Active
- Paused
- Completed

Validation:

- `Target career is required.`
- `Expected salary must be greater than 0.`
- `Target year cannot be before the current year.`

Primary:
`Save Goal`

### Skill Gap Analysis

Header:
`Skill Gap Analysis`

Show dynamically:

- Selected career
- Number of skills satisfied
- Skill-match percentage
- Skill-by-skill comparison

Each required skill displays:

- Skill name
- Required level
- Current user level
- State: Satisfied / Needs Improvement / Missing

All values must be calculated from real career requirements and the user's skills.

Do not hard-code `3 / 5` or `60%`.

CTA:
`Explore Careers`

### Career Readiness

Header:
`Career Readiness`

Show:

- Main readiness percentage
- Status
- Progress visualization
- Component weights
- Component scores
- Final result

Possible components:

- Skill Match
- Industry Alignment

All displayed values must come from the actual readiness calculation.

Do not hard-code prototype values.

### Strong Areas / Needs Improvement

Display real calculated results.

Sections:

`Strong Areas`

`Needs Improvement`

For weak or missing skills, provide clear improvement guidance.

### Readiness History

Header:
`Readiness History`

Show real historical readiness records.

Possible visualizations:

- Minimal line chart
- Vertical progress timeline

Use electric blue as the main visualization color.

Show real improvement, e.g.:

`+{difference}% improvement`

If insufficient history exists, show an empty state instead of fake chart data.

---

## 15. Validation, Loading, Empty, Success, and Error States

Do not build only ideal screens.

Support:

- Validation states
- Empty states
- Loading states
- Success states
- Delete confirmation
- Error states

### Empty State Examples

Skills:
`No skills added yet.`

Career shortlist:
`Your shortlist is empty.`

Assessment:
`Take the career assessment to see your strongest areas.`

Career goal:
`You have not set a career goal yet.`

Always provide a useful next action where practical.

### Success Examples

- `Skill added successfully.`
- `Career goal updated.`
- `Assessment completed.`

Use success green sparingly.

### Error Example

Prefer:
`Unable to load career data. Try again.`

Do not expose backend stack traces or raw technical errors.

---

## 16. Government Data Presentation

Government career/industry information should show a subtle:

`Government Data Source`

label where useful.

Do not expose database architecture, Supabase details, raw table names, or technical implementation details to normal users.

The app should feel data-driven, not technically cluttered.

---

## 17. Responsive Mobile Design

Design primarily for modern Android phones.

Primary target:

`390 × 844`

Also support:

- `375 × 812`
- `430 × 932`

Use:

- 16px horizontal margins
- Scrollable content
- Flexible card widths
- Persistent bottom navigation where appropriate
- Safe-area handling
- Keyboard-safe forms

Avoid:

- Horizontal overflow
- Fixed widths that only fit one device
- Fixed-height containers for long dynamic content

---

## 18. Dynamic Text and List Length

Assume real data can be longer than prototype examples.

Examples include:

- Long university names
- Long career names
- Long assessment questions
- Long personal notes

Use wrapping, ellipsis, `Flexible`, or `Expanded` where appropriate.

Also do not assume fixed list lengths.

Lists may contain:

- Zero records
- One record
- Many records

Use scrollable list widgets such as `ListView` where appropriate.

---

## 19. Prototype Navigation Flow

Main flow:

```text
Login
→ Home Dashboard
→ Profile
→ Skills
→ Career Explorer
→ Career Detail
→ Shortlist
→ Career Assessment
→ Assessment Results
→ Career Goal
→ Skill Gap Analysis
→ Career Readiness
→ Readiness History
```

Important interactions:

- Home → View Goal
- Home → View Readiness
- Home → Explore Careers
- Profile → Edit Profile
- Profile → My Skills
- Skills → Add Skill
- Skills → Edit Skill
- Skills → Delete Skill
- Career Explorer → Career Detail
- Career Detail → Add to Shortlist
- Career Detail → Compare
- Shortlist → Edit/Delete
- Career Assessment → Assessment Results
- Assessment Results → Career Detail
- Assessment Results → Retake Assessment
- Career Goal → Create/Edit
- Career Goal → Skill Gap Analysis
- Readiness → History

Use consistent Flutter navigation transitions.

---

## 20. Reusable UI and Theme

Before creating a component, check whether an existing shared component can be reused.

Potential reusable components:

- Primary button
- Secondary button
- App text field
- Dropdown
- Loading indicator
- Error message
- Empty state
- Confirmation dialog
- Progress card
- Section header

Centralize common values where practical:

- Colors
- Text styles
- Button styles
- Input decoration
- Card styling
- Spacing constants

Keep this simple and explainable.

Do not build an overly complicated design-system framework.

---

## 21. State-Driven UI

UI should update when application state changes.

Examples:

- Profile updated → profile UI refreshes
- Skill added → skill list refreshes
- Goal updated → dashboard goal card refreshes
- Assessment completed → assessment results refresh
- Readiness recalculated → readiness UI refreshes
- Location changed → nearby opportunity data refreshes

Do not require users to restart the app to see changes.

---

## 22. Data Display Rules

When displaying database/API values:

- Format dates consistently
- Format percentages consistently
- Format currency consistently
- Handle missing values
- Never display `null`
- Do not expose raw backend IDs
- Convert technical enum values into readable text

Example:

Backend:
`in_progress`

UI:
`In Progress`

---

## 23. Accessibility and Usability

Maintain:

- Strong contrast
- Comfortable touch targets
- Readable font sizes
- Clear selected states
- Clear validation
- Labels for important icons
- Logical form order

Do not rely on color alone to communicate meaning.

Example:
Use both a green state and the text `Satisfied`.

---

## 24. Overall Visual Standard

The application should look like a premium technical career-intelligence product, not a generic student-management app.

Maintain:

- Dark technical dashboard aesthetic
- Professional developer-tool feel
- Electric-blue interaction system
- High information density with clean spacing
- Strong typography hierarchy
- Structured cards
- Minimal visual decoration
- Data visualization
- Clear progress indicators
- Professional mobile UX

All four modules must share the same visual language.

---

## 25. Codex Implementation Rule

When implementing a screen:

1. Read the relevant feature section in `BMIT2073_Codex_Project_Specification.md`.
2. Read the relevant UI section in this file.
3. Inspect existing widgets/theme/components.
4. Reuse existing visual patterns where practical.
5. Use dynamic data interfaces when available.
6. If backend data is not ready, use temporary mock data only when necessary.
7. Keep mock data isolated and easy to replace.
8. Add loading, empty, validation, and error states where relevant.
9. Do not implement unrelated screens automatically.
10. Summarize meaningful UI files created or modified.

---

## 26. Most Important Rule

Prototype examples describe **appearance and content structure**, not fixed production data.

The final implementation should prefer:

```text
Current User Data
        +
Stored Application Data
        +
Government/Open Data
        +
Calculated State
        ↓
Dynamic UI
```

instead of:

```text
Hard-Coded Demo Values
        ↓
Static UI
```
