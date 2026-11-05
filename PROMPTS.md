# Prompts used

This challenge was completed with **Claude Code** (Anthropic, model Claude Opus 5.5) as a pair: I set direction, made the decisions and reviewed the output; the agent researched, wrote code, ran the builds and inspected the rendered goldens. The prompts below are verbatim.

## 1. Kick-off prompt

The challenge PDF was attached, together with:

> Hi I have been given this task
>
> 1: understand the assignment fully and its deliverables
> 2: research online on the best ways to complete this assignment and what are the up to date methods
> 3: also audit and act as a devil advocate in order to reach a well rounded solution
>
> Currently we have mobile apps for android and IOS. Explain what your solution is also we can make a small news app so we can test using that. also you cna ask me questions incase you need a decision or want to ask me questions to make things clear for your self

## 2. Decisions I gave when the agent asked

| Question from the agent | My answer |
|---|---|
| Which platform gets the working demo? | **iOS first, then Android**, using the same shared fixtures |
| Which platform can you defend in the interview? | "I am a QA engineer, so once the functionality is implemented I will ask you about the code and learn that way, so no documentation needed per se for me; if it's related to the task then you can do it" |
| Strategy document format? | **Markdown in the repo + PDF** |
| Packaging? | **Local git repo + CI workflow**, regression on its own branch |

## 3. How the AI was used, and where I stayed in control

- **Research:** current versions and status of swift-snapshot-testing, Roborazzi, Paparazzi, Compose Preview Screenshot Testing and Sentry/Emerge Snapshots. Known flakiness causes (simulator/GPU differences). Golden storage patterns. Public job postings to infer the BILD/WELT stack (Swift 6/SwiftUI/TCA, Kotlin/Compose/Hilt). Version numbers were checked against Maven/GitHub release pages, not taken from memory.
- **Devil's advocate:** objections and answers are in STRATEGY.md §9.
- **Build and verification:** the agent ran every build and test locally and **looked at every new golden before accepting it**. That review caught real UI bugs (banner contrast, truncated kicker, hyphenated label, missing Android hyphenation) and one test-harness bug (tall components clipped). Launching the real app then found a locale bug the snapshots structurally couldn't see. See STRATEGY.md §9.
- **What I would never delegate to AI:** approving golden changes. In the proposed process, AI may *triage* diffs or *generate* edge-case fixtures; a human code-owner approves.

## 4. Follow-up prompts

*(Questions I asked afterwards to understand the code are added here as the walkthrough continues.)*
