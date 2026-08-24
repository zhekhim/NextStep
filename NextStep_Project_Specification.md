# Mobile Application Development - Codex Project Specification

## 1. Project Context

This project is for **BMIT2073 Mobile Application Development**.

The assignment requires a mobile solution that uses **real-time or static Malaysian Government open data** to support **SDG 9: Industry, Innovation, and Infrastructure**.

The application is a student career-development system. It combines student profiles and skills, Malaysian career and industry information, a rule-based career assessment, and career-readiness analysis.

The system is divided into **4 main modules**, with one module assigned to each member.

---

## 2. Important Development Requirements for Codex

When implementing this project:

- Keep the application separated into the four modules described below.
- Do not remove or simplify substantial CRUD functionality.
- Reuse data produced by other modules where appropriate instead of duplicating it.
- Use proper input validation throughout the application, not only during login.
- Use clear, user-friendly validation and error messages.
- Keep database access separated from UI logic.
- Use both local and remote data storage where appropriate.
- Use Malaysian Government open data for career and industry information.
- Government data may be processed remotely and cached locally for offline access.
- Maintain clear ownership of each module so that each member can present their own code during the final presentation.

---

# 3. Module 1 - Student Profile & Skill Portfolio

**Owner:** Member 1

## Purpose

Build the student's academic and technical profile. The information stored here is used by the other modules, especially career matching, skill-gap analysis, and readiness scoring.

This module must be more substantial than a basic profile editor. Its main functional component is the **Skill Portfolio Management System**.

## 3.1 Account & Profile

The user must be able to:

- Register
- Login
- Create profile
- View profile
- Edit profile
- Delete account
- Select university
- Select major
- Select year of study
- Select preferred employment state

## 3.2 Skill Portfolio Management

The user must be able to:

- Add a skill
- View skills
- Edit skill level
- Delete a skill
- Search skills
- Filter skills by category

Example skill records:

| Skill | Level | Category |
|---|---|---|
| Python | Advanced | Programming |
| SQL | Intermediate | Database |
| Flutter | Intermediate | Mobile Development |

## CRUD Requirements

### Create
Add a skill to the student's portfolio.

### Read
View, search, and filter skills.

### Update
Change a skill's level or category.

### Delete
Remove a skill from the portfolio.

## Validation

Implement at least:

- Valid email format
- Password requirements
- Required profile fields
- No duplicate skills
- Valid skill levels
- Confirmation before destructive deletion
- Clear error messages

Example:

If the user already has `Python - Advanced` and tries to add Python again:

> Python is already in your skill portfolio.

## Suggested Data

### Local
- `profiles`
- `user_skills`

### Remote
- `profiles`
- `user_skills`

## Data Used by Other Modules

This module provides information for:

- Career recommendation
- Career skill matching
- Skill-gap analysis
- Career-readiness score
- Career assessment and recommendations

---

# 4. Module 2 - Industry & Career Intelligence

**Owner:** Member 2

## Purpose

Help students discover careers using Malaysian industry, employment, salary, occupation, and related government open-data information.

This module is especially important for satisfying the assignment requirement to use Malaysian Government open data.

Possible data includes:

- Industrial statistics
- Labour-force data
- Employment data
- Graduate salary data
- Occupation statistics
- Industry growth information

## 4.1 Career & Industry Explorer

The user must be able to:

- Browse careers
- Search careers
- Filter careers by industry
- Filter careers by state
- View employment statistics
- View salary statistics
- View industry growth
- View required skills
- View the government-data source
- Compare careers

Example:

### Data Analyst

- Industry: ICT
- Median Graduate Salary: RM3,800
- Industry Growth: High
- Employment Demand: Strong
- Required Skills:
  - Python
  - SQL
  - Power BI
  - Statistics

## 4.2 Career Shortlist

Users can create and manage their own career shortlist.

Example:

| Career | Priority | Preferred State |
|---|---|---|
| Data Analyst | High | Penang |
| Software Engineer | Medium | Selangor |

## CRUD Requirements

### Create
Add a career to the shortlist.

### Read
View the user's career shortlist.

### Update
Allow the user to change:

- Priority
- Preferred state
- Personal note

### Delete
Remove a career from the shortlist.

## 4.3 Mobile Feature - Location

Use device location to provide location-aware career or industry information.

Example:

### Career Opportunities Near Me

Current location: Kuala Lumpur

Possible result:

- ICT - High employment concentration
- Finance - High employment concentration
- Manufacturing - Moderate employment concentration

Another possible screen is **Nearby Industry Insights**, showing information such as industry growth and median salary for nearby states.

The user must still be allowed to manually select another state.

## Suggested Data

### Local
- `careers`
- `career_skill_requirements`
- `career_shortlists`
- `industry_statistics`
- `employment_statistics`
- `salary_statistics`

### Remote
- `careers`
- `career_skill_requirements`
- `career_shortlists`
- Processed government data

Government information can be cached locally for offline use.

---

# 5. Module 3 - Career Assessment & Recommendation

**Owner:** Member 3

## Purpose

Help students identify career areas that match their interests and working preferences through a transparent, rule-based questionnaire.

This module must describe its scoring and matching rules clearly. It must not be described as AI unless an actual AI model or service is introduced.

## 5.1 Assessment Questionnaire

The assessment contains active questions loaded from the remote database. Each question belongs to one of these dimensions:

- Technical
- Analytical
- Creative
- Business
- Leadership
- Research

Users answer each question using a five-point scale:

1. Strongly Disagree
2. Disagree
3. Neutral
4. Agree
5. Strongly Agree

The assessment flow must:

- Show one question at a time
- Show the current question number and overall progress
- Require an answer before continuing
- Allow the user to return to the previous question
- Submit only after all questions are answered
- Allow the user to retake the assessment

## 5.2 Rule-Based Dimension Scoring

For each assessment dimension:

1. Add the selected values for questions in that dimension.
2. Divide by the number of answered questions in that dimension to obtain an average from 1 to 5.
3. Convert the average to a percentage using:

```text
Dimension Score = (Average Answer / 5) x 100
```

Example:

```text
Technical answers: 4, 5, 3, 4
Average = 4
Technical Score = (4 / 5) x 100 = 80%
```

The result screen shows all dimension scores in ranked order and highlights the three strongest areas.

## 5.3 Rule-Based Career Matching

Each supported career has a stored target profile containing a value from 1 to 5 for every assessment dimension.

The matching service compares the user's dimension values with each career profile:

```text
User Dimension Value = Dimension Percentage / 20
Total Difference = Sum of the absolute differences across all 6 dimensions
Career Match = (1 - Total Difference / 24) x 100
```

The final percentage is limited to the range 0 to 100. Careers are sorted from the highest match to the lowest match, and the top five are displayed.

Each recommendation shows:

- Rank
- Career name
- Match percentage
- Action to open the existing career detail screen

From the career detail screen, the user can set the recommended career as their active career goal. If another goal exists, the application must confirm replacement, preserve its optional goal details, and navigate directly to the Career Goal page after the replacement succeeds.

## 5.4 Data and Error Handling

Remote tables used by this module:

- `assessment_questions`
- `career_assessment_profiles`
- `careers` through the existing career relationship

The UI must handle:

- Loading questions
- No active questions
- Failure to load questions
- Missing answers
- Loading career matches
- No available career profiles
- Failure to generate career matches

This module demonstrates remote-data retrieval, validation, transparent score processing, rule-based recommendation, and cross-module navigation.

---

# 6. Module 4 - Career Goal & Readiness Intelligence

**Owner:** Member 4

## Purpose

Evaluate how prepared a student is for a selected career and clearly explain which areas are preventing the student from becoming more prepared.

This module should use data from the other modules instead of asking the user to enter the same information again.

---

## 6.1 Career Goal Management

Example career goal:

- Target Career: Data Analyst
- Target Industry: ICT
- Preferred State: Penang
- Target Graduation: 2027
- Expected Salary: RM4,000
- Status: Active

## CRUD Requirements

### Create
Create a career goal.

### Read
View the career goal.

### Update
Change career-goal details.

### Delete
Remove the career goal.

---

## 6.2 Skill Gap Analysis

Compare the student's skills from Module 1 with the required skills for the selected career.

Example career requirements:

| Skill | Required Level |
|---|---|
| Python | Intermediate |
| SQL | Intermediate |
| Power BI | Intermediate |
| Excel | Intermediate |
| Statistics | Beginner |

Example student skills:

| Skill | Current Level | Result |
|---|---|---|
| Python | Advanced | Satisfied |
| SQL | Intermediate | Satisfied |
| Power BI | Beginner | Insufficient |
| Excel | Advanced | Satisfied |
| Statistics | Not Added | Missing |

Example calculation:

- Skills satisfied: `3 / 5`
- Skill Match: `60%`

The UI should clearly display missing or insufficient skills.

Example:

### Power BI
- Required: Intermediate
- Current: Beginner

### Statistics
- Required: Beginner
- Current: Not Added

Use a transparent rule-based comparison rather than vague or unexplained "AI".

---

## 6.3 Career Readiness Score

Calculate a transparent career-readiness score.

Example weighting:

| Component | Weight |
|---|---:|
| Skill Match | 70% |
| Industry Alignment | 30% |

Example values:

- Skill Match = 70
- Industry Alignment = 90

Calculation:

```text
70 x 0.70 = 49
90 x 0.30 = 27

Career Readiness = 76%
```

The UI can display:

- Career Readiness: 76%
- Progress status such as `Good Progress`
- Strong areas
- Areas needing improvement

Example strong areas:

- Python
- SQL
- Excel

Example areas needing improvement:

- Power BI
- Statistics

---

## 6.4 Readiness History

Store readiness scores over time so the user can see progress.

Example:

| Month | Readiness |
|---|---:|
| August | 58% |
| September | 67% |
| October | 74% |

The application can then show:

`+16% improvement`

This feature should demonstrate actual data processing rather than only CRUD operations.

---

# 7. Data Architecture

The application should separate the UI from database operations.

Recommended flow:

```text
Malaysian Government API
        |
        v
Processed Government Data
        |
        v
Remote Database
        |
        v
Local Cache
        |
        v
Repository / Data Layer
        |
        v
Application UI
```

For user-generated data, a possible synchronisation flow is:

```text
Create / Update / Delete
        |
        v
Local Database
        |
        v
Remote Database Sync
```

The UI should not directly communicate with databases throughout the application. Database operations should be handled through an appropriate repository/data layer.

---

# 8. Data Storage Responsibilities

## User-generated data

Examples:

- Profiles
- Skills
- Career shortlists
- Assessment questions
- Career assessment profiles
- Career goals
- Readiness history

These should support appropriate local and remote persistence.

## Government/open data

Examples:

- Careers
- Career skill requirements
- Industry statistics
- Employment statistics
- Salary statistics

Government data can be:

```text
Government API
-> Process / transform data
-> Remote database
-> Local cache
-> Application
```

---

# 9. Input Validation Across All Modules

Validation must be implemented throughout the application.

| Field | Validation |
|---|---|
| Email | Valid email format |
| Password | Must meet minimum requirements |
| Skill | Cannot be empty or duplicate |
| Skill Level | Must use valid options |
| Salary | Must be greater than 0 |
| Target Year | Cannot be before the current year |
| Career Priority | High / Medium / Low |
| Assessment Answer | Required and must be from 1 to 5 |
| Career Goal | Target career is required |

Use useful UX messages.

Avoid:

> Error

Prefer:

> Deadline cannot be earlier than today.

---

# 10. Cross-Module Dependencies

Codex should preserve these relationships:

```text
Module 1: Student Profile & Skills
                        |
                        v
Module 2: Career Data & Career Profiles
             |                      |
             v                      v
Module 3: Career Assessment   Module 4: Skill Gap & Readiness
             |
             v
Rule-Based Career Recommendations
             |
             v
Module 2: Career Detail
```

Important examples:

- Module 4 reads student skills from Module 1.
- Module 4 reads career requirements and industry information from Module 2.
- Module 3 reads assessment questions and career assessment profiles from the remote database.
- Module 3 reuses career records from Module 2 when displaying recommendations.
- Module 3 opens the existing Module 2 career detail screen when the user explores a recommended career.
- Assessment recommendations and Module 4 readiness scores are separate transparent calculations unless a later requirement explicitly connects them.
- Do not duplicate these records unnecessarily between modules.

---

# 11. Assignment Constraints to Keep in Mind

The assignment requires the team to:

- Build a mobile application.
- Use real-time or static Malaysian Government open data.
- Support SDG 9.
- Demonstrate meaningful mobile-development methods.
- Demonstrate substantial individual work.
- Demonstrate good data management.
- Use strong input validation.
- Maintain a private GitHub repository showing active contributions from all members.
- Be able to perform a structured code walkthrough where each member presents their own module.

The assignment also states that comments must be removed from the submitted codebase. During development, comments may still be useful, but ensure the final submission follows the lecturer's requirement.

---

# 12. Guidance for Codex

When asked to implement a feature:

1. Identify which of the four modules owns the feature.
2. Check whether required data already belongs to another module.
3. Reuse existing models/repositories/interfaces where possible.
4. Do not rewrite unrelated teammates' modules unless integration requires a minimal change.
5. Keep business logic outside UI widgets/screens where practical.
6. Validate all user input.
7. Handle loading, empty, success, and error states.
8. Preserve CRUD completeness.
9. Keep calculations transparent and reproducible.
10. Maintain clear separation between user-generated data and government/open data.
11. Keep local/remote synchronisation behavior consistent.
12. Avoid claiming a feature uses AI when it is actually a deterministic calculation.
13. Prefer clear algorithms that can be explained during the final code walkthrough.

---

# 13. Definition of Done

A feature is not considered complete only because the UI exists.

For each implemented feature, check:

- UI is connected to real application logic.
- Required data can be created/read/updated/deleted where applicable.
- Input validation is implemented.
- Errors are handled with meaningful messages.
- Data persists correctly.
- Cross-module data is reused correctly.
- Loading and empty states are handled.
- Calculations produce consistent results.
- Mobile-specific functionality works where required.
- The implementation can be clearly explained by the responsible member.
