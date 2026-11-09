# Prompts used

This challenge was completed with **Claude Code** (Anthropic, model Claude Opus 5.5) as a pair-programming agent. I set the direction and made the product and scope decisions below. The agent researched, wrote the code and docs, ran every build and test, and did a first-pass review of every rendered golden. The prompts are quoted verbatim (one work e-mail address redacted).

## 1. Decisions I made (and where I overrode the defaults)

| Decision | What I chose | Why it matters |
|---|---|---|
| Demo scope | **Both platforms**, iOS first, sharing one fixture set | Proves the "both platforms without doubling effort" claim with code |
| Article content | **Real public headlines + link out**, no copied article text (I rejected bundling full articles) | Copyright-safe; the publisher's page opens in-app |
| Games tab | Built-in classics (Tic-Tac-Toe, pairs, Mini-Sudoku) instead of embedded web games | Offline, deterministic, so every state can be snapshot-tested |
| Deliverable format | Markdown + PDF in a local git repo with a CI workflow; regression on its own branch | Reviewers can run it and see the failing diff |
| Attribution | No AI co-author in the git history | The submission is mine |
| Quality bar | Asked for repeated audits, including **five role-based reviews** (product manager, senior developer, senior QA, accessibility/design, hiring panel), and had their findings implemented | See STRATEGY.md, Appendix A |

**Golden approval.** The agent did a first-pass review of each new golden, which caught the real bugs listed in STRATEGY.md Appendix A. Final approval of what is committed as a golden is mine, as the candidate. That mirrors the proposed process: AI may triage, a human code owner approves.

## 2. Prompts

**Kick-off** (with the challenge PDF attached):

> Hi I have been given this task
>
> 1: understand the assignment fully and its deliverables
> 2: research online on the best ways to complete this assignment and what are the up to date methods
> 3: also audit and act as a devil advocate in order to reach a well rounded solution
>
> Currently we have mobile apps for android and IOS. Explain what your solution is also we can make a small news app so we can test using that. also you cna ask me questions incase you need a decision or want to ask me questions to make things clear for your self

**Answers to the agent's questions:** iOS first, then Android; Markdown + PDF; local git repo + CI workflow; and:

> I am a qa engineer so once the funiotnlity is implemented I will ask you about the code and learn that way so no documentation needed persay for me if it related to the task then you can do

**Follow-ups, in order:**

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

(Decisions for that round: real headlines + link out, built-in classic games, both iOS and Android.)

> audit everything and finish a run and give me commands at the end after validation of those commands working

> now put sub agenets one as Product manager, one as senior developer, one as senior qa etc which you think will be beneficail for this prodect and get an audit form them too , do the imrpovements they mention scenarios coerd. they think of etc, then give me commands again weather these irpovement are to the app to cover more scneraios etc or to the way we are using se=creenshots

> do the imrpvements accouring to the agents responses then a few questions/ things to do
>
> 1: are we using mock data as for examkple our app is a news app or somerhing simlar where content can change so hw chould the golden sample work if they are old , hos do we deal with that
> 2: when in the CI/CD piepline it should run ? and I will soon give you. github to connect to you are ready to interact with it
> 3: how do we deal with just a litle diference and that has human confimartion to do ? etc . and what type and scale of differnece do we allow or do we have flags for those too for user confirmation is that the best solution or not etc
> 4: and now that you hae more knoeldge of the type of app to keep in mind come up with more edge canses so we can implement those and wat is the best solution to deal with apps that have contnuesly changing data ,so do we mock data etc those kind of thinking behind the reserch you do for the latest best solution for our case

## 3. How the AI was used

- **Research:**
  - current versions and status of swift-snapshot-testing, Roborazzi, Robolectric, Paparazzi, Compose Preview Screenshot Testing, Sentry/Emerge Snapshots and GitHub runner images
  - known flakiness causes
  - golden storage patterns
  - versions were checked against release pages, not taken from memory
- **Stack assumptions:** the BILD/WELT stack (Swift 6/SwiftUI/TCA, Kotlin/Compose/Hilt) was **inferred from public job postings** and is labelled as an assumption in the strategy.
- **Reviews:** a devil's-advocate pass, two full audits, and five parallel role-based reviews. Each finding was verified in the code before it was acted on.
- **Checks that must be able to fail:** every new guard (fuzz test, image contract, accessibility checks) was first shown to fail on a deliberately broken input. One didn't: Google's Compose accessibility hook silently checks nothing under Robolectric, so it was replaced.
- **Never delegated:** approving golden changes.
