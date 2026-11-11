# Prompts used

This challenge was completed with **Claude Code** (Anthropic, model Claude Opus 5.5) as a pair-programming agent. I set the direction and made the product and scope decisions below. The agent researched, wrote the code and docs, ran every build and test, and did a first-pass review of every rendered golden. The prompts are quoted verbatim (one work e-mail address redacted).

## 1. Decisions I made (and where I overrode the defaults)

| Decision | What I chose | Why it matters |
|---|---|---|
| Demo scope | First **both platforms** sharing one fixture set; then **cut to iOS only** to keep the presentation focused, with Android described in the strategy (§10) | The two-platform version proved the shared-fixture idea and found real bugs (docs/EVIDENCE.md); one platform is easier to show well |
| Article content | **Real public headlines + link out**, no copied article text (I rejected bundling full articles) | Copyright-safe; the publisher's page opens in-app |
| Games tab | Built-in classics (Tic-Tac-Toe, pairs, Mini-Sudoku) instead of embedded web games | Offline, deterministic, so every state can be snapshot-tested |
| Deliverable format | Markdown + PDF in a local git repo with a CI workflow; regression on its own branch | Reviewers can run it and see the failing diff |
| Attribution | No AI co-author in the git history | The submission is mine |
| Hosting and CI | My personal GitHub account; commit authorship rewritten to my GitHub no-reply address before the first push; finally a fresh **public** repo without the Android code (public Actions minutes are free) | No work e-mail published; CI proven on real runners |
| Merges | I review the golden diffs and merge PRs myself; the agent was not allowed to merge | Mirrors the proposed process: a human code owner approves goldens |
| Quality bar | Asked for repeated audits, including **five role-based reviews** (product manager, senior developer, senior QA, accessibility/design, hiring panel), and had their findings implemented | See docs/EVIDENCE.md |

**Golden approval.** The agent did a first-pass review of each new golden, which caught the real bugs listed in docs/EVIDENCE.md. Final approval of what is committed as a golden is mine, as the candidate. That mirrors the proposed process: AI may triage, a human code owner approves.

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

> short answer what of the deliverables are left etc

> i want you to upload to https://github.com/SaadiIftikhar and run and test the whole CI/CD pipeline

(Decisions for that round: private repo; authorship rewritten to the GitHub no-reply address.)

> done

> did the IOS finish?

> okay what deliverables are left and what imrpovements we can do to the process  also add caveman skill if not done yet

> jutst the 9nes left

> merge done

> done what is left

> what is left

> what is github actions its saying i have used 90 percent and will be charged for more, so did we use that and how can we remove that or do we want to

> is the CI/CD part of the cahlenge or delivarbles?

> run locally from end to end also verofy comamnds etc and if CI/CD is not needed then we can ignore for now, okay now give me an unserstanding of how the process will work with commands etc so I can unserstand what you have done

> come up with a script on the best way to present this  that and if you can give me power point presentation that I can use while representing , if you cant make then give me a pormt with words that will be part of it so i can give it to LCaude for the power point

> also keep in mind for the presentationa nd script that I will be running code alongs side it showing , so kindly in the notes wirte what commands to run , where to show in folder etc for results golden standards etc

> i will ask a few questios while going through the script and presentation right now , keep the answer to minum Two: we render the real production screen with that data, inside a fast test. No network, no emulator., what is a fast test and how it works

> why simulator on ios and not android

> (a screenshot of the slide text "one regression fails on both, in the same places") in rpesentation what does mena

> incase android an IOS apps are visaully slightly difrent how do we deal with that

> when and how are we revieing these diffrences and what commands are connected to this rpocess

> okay lets do this first give me a discription of hwere everything is put folder etc, the commands to run , and explain the rpocess to me step by step with comamnds in a dev/qa workflow way so I have an undetstnading from end to end, also keep in mind negative screnrios like a test failing how we decide etc and if we need to add new screen shot and if there are changes that change the approence and how we comapre like the golden how do we add that for new changes etc

> i dont see these 2 in fictures (the `artifacts/ios/diffs` and `artifacts/android/diffs` folders)

> in the commands also add what the command does a little desciption and why

> as some of these files are missing from the folder like in artifcats etc just put a files there so i can view and undetadn better also for other places where wemihgt get it

> now imrpove the presentation script etc and guide me the best way to present my project and what should i do in each step. for exmaple i am on slides 1 the script and int he script it alwso should say which and a seperate scirpts file for commands to run before my presentation so its ready and the commands to run while rpesenting for the slides etc and he coands file should have a decpriotn of what the comamnds do . and in a way that makes it clear for me now and who I am repsenting to later how its done

> kindly also give me a script for just running the project and exmapling it and not showing the presentation

> okay now lets do a few things
>
> before optimize your self so oyou get all the context for this task
>
> 1: Let remove the whole android verion from this project if its the app the test, artificats etc as we only need to show 1 of them i think it would be better if we just focus on IOS, form the app to the tests, to ci/cd we will be better and at the end we can also tell them what can be done on android in the same way. also remove from the github the code for related to android
>
> 2: make folder more neat and contenets in it
>
> 3: make sure every deliverable is accounted for for this task
>
> 4: run the IOS test from end to end even on the CI/CD piepe line and audit everything is working and ready
>
> 5: then remve all the files form te presentation folder and make 1 power point presentation, one scrit that has all the commands i should run before the presentation then the script plus each commands and folder to show (should the temrinal and can the copied easily for every command,  with copy button)  etc also. and also one script which i should use if powerpoint presentation is not needed then the flow
>
> you can ask me to do thing in between which you might now be able to do

(Decisions for that round: the repo becomes public for the CI runs, since it is presented the next day; the nightly CI run is removed to save minutes.)

> I have dleted the repo so once you have done the task i have given you you can upload as public with android removed and other things done

> in demo without code also give me a script with the commands so i know they way we take the presentation

> ok for the script with out code, make the setup script more robust so all the things i am doing to point to in the code less presentation vs code tabs in order , simulater aopp etc and then remove the commands from the script for those only the ones for the files as they will be open just give me commands that are needed to run for presentation and in text oyu can say in the vs code the tab this anme shows xcode for test etc and lets focus on the mian script and the coe less script and remove th presentation and also check in the maint ask document if power point presentation is needed if not then remove the rpesentation and the script connected t it just leave the code less script file nothing lese and the imicial script command, also before you give me these run the commands the steup script and the commands in the presentation so everyone of them are well.

(Decision for that round: the brief asks only for an optional recording or notes, not slides, so the PowerPoint and its scripts were removed. presentation/ now holds one talk track and one setup script, both generated from scripts/presentation/generate.js.)

> okat also in the script without code add the files you want me to show wiht the say part that is connectd to it no speratly as it is easier that wya

> 1: lets shorten the scirpt plus commands as we are going too deep into things , make the judgemnt call and reduce it atlest 40 pecent 2: ALSO IN THE APP LOGIN SCREEN THE USER EMAIL AND APPSWORD SHOULD ALREADY BE FILLED AND YOU CAN UPDATE STEUP AND SCREEN SHOT TEST ACCORDINGLY … ONCE EVERYTHING IS DONE RESTART MY PC

(Decisions for that round: the script went from 14 sections and 12 live commands to 9 and 6, about 68% fewer words. Tolerance, safety nets and CI details moved to the "If they ask" answers. The login pre-fill applies only to the demo app; the screenshot tests pass explicit values, so no golden changed, and the empty-form golden still covers the placeholders.)

> in the presentation folder make another file which has the script but more details on the steps so if someone read that for the first time they will underttand and also add visual aid in the file and also explain simpler things like , also cover questions and other deatils like scrfnearios for exmaple when no change when there is some change etc and visual aids will be great ake a presentation just to undertand everythign related and how everything is in the worklfow so a new person cna easily undetand it

> okay then lets remove the CI part fromm the script tabs in setup script etc and just imrpove if needed the document stragry i think it was right , and see if script is working also remove the fnial html form the rpesentation file delete it and the rest delete everything in roesnetaion fodoler and then make a script form new without old thinking just the task and this projecy in mind and make a new script and focus on the flow of the scirpt too and update test steup accrdintly and make a run then resart this pc immdtialty … so presnetation script and steup sct two deliverable right now

(Decisions for that round: the CI pipeline stays in the repo and the strategy, but the live script no longer shows GitHub. The script was rebuilt from scratch on two demo practices found in research, "show the result first" (Great Demo!) and tell–show–tell, with the decisions and trade-offs spoken out. The strategy was reviewed and left unchanged.)

## 3. How the AI was used

- **Research:**
  - current versions and status of swift-snapshot-testing, Roborazzi, Robolectric, Paparazzi, Compose Preview Screenshot Testing, Sentry/Emerge Snapshots and GitHub runner images
  - known flakiness causes
  - golden storage patterns
  - versions were checked against release pages, not taken from memory
- **Stack assumptions:** the BILD/WELT stack (Swift 6/SwiftUI/TCA, Kotlin/Compose/Hilt) was **inferred from public job postings** and is labelled as an assumption in the strategy.
- **Reviews:** a devil's-advocate pass, two full audits, and five parallel role-based reviews. Each finding was verified in the code before it was acted on.
- **Checks that must be able to fail:** every new guard (fuzz test, image contract, accessibility checks) was first shown to fail on a deliberately broken input. One didn't: Google's Compose accessibility hook silently checks nothing under Robolectric, so it was replaced.
- **Never delegated:** approving golden changes and merging pull requests.
