# AGENTS.md

## Project Overview

This repository contains a Flutter mobile application developed mainly for Android for the BMIT2073 Mobile Application Development assignment.

The application is divided into four main functional modules:

1. Student Profile & Skill Portfolio
2. Industry & Career Intelligence
3. Learning & Certification Tracker
4. Career Readiness & Goal Management

The detailed functional requirements are defined in:

`NextStep_Project_Specification.md`

Before implementing a feature, read the relevant section of that specification and follow it as the main functional reference.

If the repository contains a UI/design Markdown file, read it before creating or changing screens, widgets, layouts, colours, typography, navigation appearance, or other visual elements.

---

# 1. Development Approach

Work feature-by-feature and function-by-function.

Do not try to build the entire application at once unless explicitly instructed.

The user will normally request one function or one development step at a time. Complete the requested scope first, while making reasonable supporting changes needed for that feature.

Use a balanced level of autonomy:

- Follow the user's requested direction and sequence.
- You may make small supporting decisions without asking for permission.
- You may create necessary files, models, repositories, widgets, validators, or helper methods when they are clearly required by the requested feature.
- Do not introduce major architecture changes, large refactors, or unrelated features without explaining why first.
- Do not implement future modules or functions simply because they are listed in the specification.
- Keep the implementation understandable enough for students to explain during a code walkthrough.

Avoid both extremes:

- Do not make the implementation unnecessarily simplistic just to reduce code.
- Do not over-engineer the application with patterns, abstractions, packages, or layers that do not provide a clear benefit.

Prefer the simplest implementation that is still clean, maintainable, and suitable for the assignment.

---

# 2. Platform and Technology

Primary framework:

- Flutter
- Dart
- Mainly Android

Possible data technologies:

- Supabase
- SQLite
- Malaysian Government Open Data APIs

The exact database/API choice for individual features may not be finalized yet.

Do not assume that every feature must use all three technologies.

Before implementing persistence or external-data functionality, determine which data source is appropriate for that feature based on the project specification and the user's instruction.

---

# 3. Project Structure

Follow the existing feature-based project structure.

Main structure:

```text
lib/
├── main.dart
├── app.dart
├── routes/
├── core/
├── auth/
└── modules/
    ├── profile_skills/
    ├── career_intelligence/
    ├── learning_tracker/
    └── career_readiness/
```

Shared functionality belongs outside individual modules when appropriate.

Important shared areas include:

```text
core/database/
core/supabase/
core/sync/
core/services/
core/utils/
core/widgets/
auth/
routes/
```

The intended data flow is generally:

```text
Flutter Screen
    ↓
Repository
    ↓
SQLite / Supabase / Processing Service
```

For government data, the intended general flow is:

```text
Government Open Data
    ↓
Processing / API Service
    ↓
Supabase when needed
    ↓
SQLite cache when needed
    ↓
Flutter Application
```

Do not force this full flow onto every feature if a simpler path is sufficient.

---

# 4. Folder and File Rules

Place code in the folder that matches its responsibility.

Examples:

- Data models → `models/`
- Data access → `repositories/`
- Feature-specific processing/business logic → `services/`
- Screens/pages → `screens/`
- Reusable feature UI → `widgets/`
- Shared validation → `core/utils/`
- Shared application services → `core/services/`
- Shared SQLite configuration → `core/database/`
- Shared Supabase functionality → `core/supabase/`
- Navigation → `routes/`

Do not create files merely because they appear in the planned folder structure.

Create a file when a real implemented feature needs it.

Do not create unnecessary placeholder classes or empty architecture layers.

---

# 5. Existing Code and Team Collaboration

Existing teammate code may be reused or called when needed.

Examples include:

- Models
- IDs
- Repositories
- Authentication state
- Shared services
- Common widgets
- Existing navigation
- Existing database helpers

Prefer integration over duplication.

Do not copy another module's data into a new model or table unless there is a real technical reason.

## Shared Code Changes

Before making a meaningful change to shared code, explain why the shared change is required.

Shared code includes areas such as:

```text
core/
auth/
routes/
main.dart
app.dart
shared database configuration
shared Supabase configuration
shared services
shared widgets
```

Small obvious fixes do not require a long explanation.

For larger shared changes, state:

- Why the change is needed
- Which feature requires it
- Which other modules may be affected

Do not make broad shared refactors just to match a personal coding preference.

---

# 6. Naming and Refactoring Rules

Do not rename existing files, classes, methods, routes, database tables, or important identifiers without a clear reason.

If a rename is genuinely needed:

1. Explain why.
2. Check the references that will be affected.
3. Update all affected references consistently.
4. Mention the rename in the change summary.

Avoid large refactors unless they directly improve or unblock the requested feature.

Do not change working code simply because another style is possible.

---

# 7. Change Summary Requirement

After completing a meaningful implementation, provide a concise summary of what changed.

Include:

- Files created
- Files significantly modified
- Main functionality added
- Shared areas affected
- Database/API changes, if any
- Anything the user should test

Minor edits such as formatting, imports, or very small internal changes can be omitted.

A typical summary can look like:

```text
Changes made:
- Added skill creation screen.
- Added duplicate-skill validation.
- Added SkillRepository addSkill().
- Updated app_routes.dart with the Add Skill route.

Affected areas:
- profile_skills
- shared routing
```

Do not produce an excessively detailed line-by-line change log unless requested.

---

# 8. Supabase MCP Safety Rule

The user may work on multiple projects that use different Supabase databases.

Never assume that an already configured Supabase MCP connection belongs to this repository.

Before reading, creating, modifying, or deleting Supabase database objects through MCP:

1. Verify the currently connected Supabase project.
2. Confirm that the project belongs to this repository.
3. Check the project identifier/name when available.
4. If the connection appears to belong to another project or cannot be verified, stop and inform the user before making database changes.

Never:

- Reuse another project's Supabase database accidentally.
- Apply migrations to an unverified project.
- Create tables in an unverified project.
- Delete or alter data in an unverified project.
- Assume that a previous Codex session's MCP connection is correct.

When this project's Supabase connection is established, use only that verified project for this repository.

---

# 9. SQLite Rules

The project should use one shared SQLite database rather than creating a separate SQLite database for each module.

Shared database configuration belongs in:

`core/database/`

Individual modules may have their own repositories and models, but they should use the shared database infrastructure.

Before adding a new SQLite table:

- Check whether an existing table already stores the required data.
- Avoid duplicate tables representing the same entity.
- Keep table structure understandable.
- Use suitable primary keys and foreign keys when needed.
- Consider how the data may synchronize with Supabase later.

Do not add complicated offline synchronization logic unless the requested feature actually needs it.

---

# 10. Government API Rules

Government open data is an important assignment requirement, especially for career and industry intelligence.

When implementing government-data functionality:

- Use an official or appropriate Malaysian Government open-data source where possible.
- Keep API/network logic outside UI screens.
- Use a service or repository layer.
- Convert API responses into clear application models.
- Handle unavailable or incomplete API responses.
- Show loading, empty, and error states.
- Cache data locally only when useful.
- Do not hard-code fake government statistics into production logic unless temporary mock data is explicitly requested during development.

If mock data is temporarily used, keep the implementation easy to replace with the real API later.

---

# 11. UI and Design Rules

Follow the project's UI/design Markdown file when one exists.

Before creating a new screen:

1. Check the existing UI rules.
2. Check existing shared widgets.
3. Reuse existing design patterns where practical.
4. Keep visual behaviour consistent across modules.

Do not redesign unrelated screens while implementing a function.

Prefer reusable widgets when repetition is meaningful, but do not extract every small widget into a separate file.

Keep the interface suitable for Android mobile screens.

Handle important UI states:

- Loading
- Empty data
- Validation error
- Operation success
- Operation failure

---

# 12. Code Complexity

Code must be suitable for a student project and understandable during presentation.

Prefer:

- Clear names
- Short and focused methods
- Straightforward control flow
- Simple repository methods
- Transparent calculations
- Easy-to-follow validation
- Small reusable widgets where useful

Avoid unnecessary use of:

- Deep inheritance
- Excessive generic abstractions
- Complex design patterns
- Large dependency-injection frameworks
- Unnecessary code generation
- Multiple wrappers around simple operations
- Highly abstract architecture that is difficult to explain

Use a more advanced approach only when it provides a clear technical benefit.

The goal is:

> Clean and credible, but still explainable.

---

# 13. Business Logic

Do not place substantial business logic directly inside UI widgets when it can reasonably live in a repository, service, model helper, or other appropriate layer.

Examples of business logic include:

- Readiness score calculation
- Skill-gap comparison
- Data transformation
- Database operations
- API processing
- Synchronization
- Complex validation

UI code should mainly handle:

- Display
- User input
- Screen state
- Navigation
- Calling the appropriate logic

Do not create a separate service for trivial one-line logic unless there is a real reuse or separation benefit.

---

# 14. Validation

Validate user input throughout the application.

Examples include:

- Email format
- Password requirements
- Required fields
- Duplicate skills
- Valid skill levels
- Positive salary values
- Valid dates
- Valid target graduation year
- Progress between 0 and 100
- Valid priority values
- Required career goal information

Use clear messages.

Prefer:

`Deadline cannot be earlier than today.`

Instead of:

`Error`

Validation should be understandable and easy to demonstrate.

---

# 15. Error Handling

Do not silently ignore errors.

For important operations:

- Catch expected failures.
- Return or display a useful message.
- Keep the app usable after the failure.
- Avoid exposing sensitive backend details to the user.

Do not add excessive `try/catch` blocks everywhere when they provide no value.

Handle errors at the most appropriate layer.

---

# 16. Dependencies and Packages

Do not add a Flutter/Dart package unless it provides a clear benefit.

Before adding a package:

- Check whether Flutter/Dart already provides the required capability.
- Prefer established packages.
- Avoid packages that duplicate existing project functionality.
- Avoid adding a large package for a very small feature.

For significant new dependencies, mention the package and why it is needed.

Do not upgrade unrelated packages while implementing a feature unless necessary.

---

# 17. Authentication

Authentication is shared application functionality and does not belong exclusively to one functional module.

Authentication-related code belongs under:

`auth/`

Use shared authenticated-user information rather than asking individual modules to create their own login/session logic.

Modules may read the authenticated user's identifier when needed.

Do not duplicate authentication logic inside each module.

---

# 18. Cross-Module Integration

Modules may use data from other modules.

Examples:

- Career Readiness can read skills from Student Profile & Skill Portfolio.
- Career Readiness can read career requirements from Career Intelligence.
- Learning Tracker can use skill gaps to guide learning tasks.
- Career Readiness can use learning and certification progress.

When integrating modules:

- Prefer existing repository/model interfaces.
- Avoid direct duplication of records.
- Keep dependencies understandable.
- Avoid tightly coupling screen classes to one another.
- Make only the minimum shared changes required.

---

# 19. Readiness and Skill-Gap Logic

Career-readiness and skill-gap calculations must be transparent.

Do not describe deterministic calculations as AI unless an actual AI model/service is being used.

The user should be able to explain:

- Inputs
- Weights
- Comparison rules
- Formula
- Output

Keep algorithms reproducible and easy to test.

---

# 20. Comments and Assignment Submission

During development, comments may be used when they genuinely help explain difficult code.

Avoid excessive comments that simply repeat what the code already says.

The assignment requires comments to be removed from the final submitted codebase.

Therefore:

- Development comments are acceptable when useful.
- Do not depend on comments to make confusing code understandable.
- Keep names and structure clear.
- Before final submission, remove code comments as required by the assignment.

Do not remove comments automatically during normal development unless the user asks for submission cleanup.

---

# 21. Testing and Verification

After implementing a function:

- Check for obvious Dart errors.
- Run formatting where appropriate.
- Run relevant static analysis/tests when available.
- Check affected navigation.
- Check input validation.
- Check empty/error states.
- Check persistence if the feature stores data.

Do not claim something was successfully tested if it was not actually run.

If testing requires credentials, a connected Supabase project, an Android device/emulator, or a government API that is not available, clearly state what remains unverified.

---

# 22. Step-by-Step Work Rule

The default workflow should be:

```text
Understand requested function
        ↓
Inspect relevant existing files
        ↓
Identify minimal required changes
        ↓
Implement requested function
        ↓
Add only necessary supporting code
        ↓
Check affected code
        ↓
Summarize meaningful changes
        ↓
Wait for the user's next requested function
```

Do not continue automatically into the next major function unless explicitly asked.

---

# 23. When Requirements Are Unclear

If a small implementation detail is unclear, choose a sensible, simple approach that matches the existing project.

Ask the user before proceeding when the uncertainty affects something significant, such as:

- Database schema direction
- Supabase project selection
- Major architecture
- Destructive changes
- Large shared-code changes
- Changing the meaning of a required function
- Introducing a major package or framework
- Replacing an existing working implementation

---

# 24. Priority Order

When instructions conflict, follow this priority:

1. The user's latest explicit instruction
2. `AGENTS.md`
3. `BMIT2073_Codex_Project_Specification.md`
4. UI/design Markdown documentation
5. Existing project conventions and code
6. Sensible Flutter/Dart conventions

If the user's latest instruction intentionally changes an earlier project rule, follow the latest instruction and mention significant consequences when relevant.

---

# 25. Main Principle

Build the application progressively.

Each function should be:

- Functional
- Understandable
- Properly structured
- Validated
- Easy to explain
- Integrated with existing code
- No more complex than necessary

Make reasonable supporting improvements, but keep the requested feature as the main scope of each development step.
