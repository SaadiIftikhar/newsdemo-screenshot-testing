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
| Which platform can you defend in the interview? | "I am a qa engineer so once the funiotnlity is implemented I will ask you about the code and learn that way so no documentation needed persay for me if it related to the task then you can do" |
| Strategy document format? | **Markdown in the repo + PDF** |
| Packaging? | **Local git repo + CI workflow**, regression on its own branch |

## 3. How the AI was used, and where I stayed in control

- **Research:** current versions and status of swift-snapshot-testing, Roborazzi, Paparazzi, Compose Preview Screenshot Testing and Sentry/Emerge Snapshots. Known flakiness causes (simulator/GPU differences). Golden storage patterns. Public job postings to infer the BILD/WELT stack (Swift 6/SwiftUI/TCA, Kotlin/Compose/Hilt). Version numbers were checked against Maven/GitHub release pages, not taken from memory.
- **Devil's advocate:** objections and answers are in STRATEGY.md §9.
- **Build and verification:** the agent ran every build and test locally and **looked at every new golden before accepting it**. That review caught real UI bugs (banner contrast, truncated kicker, hyphenated label, missing Android hyphenation) and one test-harness bug (tall components clipped). Launching the real app then found a locale bug the snapshots structurally couldn't see. See STRATEGY.md §9.
- **What I would never delegate to AI:** approving golden changes. In the proposed process, AI may *triage* diffs or *generate* edge-case fixtures; a human code-owner approves.

## 4. Follow-up prompts

> Continue from where you left off.

> audit everything and all the deliverables and also let me know if you want me to verify something form my side

> also remove claude from the contributors please incase i upload to gihub i dont want it to be there and yes no need to upload to github with [work e-mail removed] I will be using personel. I dont think we need to upload to github as I just have to present it

> give me all the commands etc and where to execute them to run a test and see app on simulater or phone etc

> simualter is not the case for new xcode kindyl have a look and update commands

> 1: audit everything and verify by researhcing online etc that what we have implemented is up tod ate and robust
> 2: research and apply fixes / imrpovements
> 3: also for the app make 3 tabs at the bottom hovering bar with news feed , games and account
> 4: to the feed add real articles and we should be able to opent he articles just take from publically avialable once , in games the user should be able to see a few games which can be played see publically avaible short and then 3rd page with account login
> 5: after makingthe app better make test for the other screens now too
> 6: once imporvemnt and tests are made audit everything again and run every tests also go through each command so each one of them hold true
> 7: then give me imrportant information summary i need along with all the use full commands and where to run them

Decisions I gave for that round: **real headlines + link out** (no copied article text), **built-in classic games**, **both iOS and Android**.

*(Questions I asked afterwards to understand the code are added here as the walkthrough continues.)*
