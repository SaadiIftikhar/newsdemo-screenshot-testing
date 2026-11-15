-- NewsDemo Runner: lets the slide deck's buttons run the live-demo commands in Terminal.
-- PowerPoint can open a link (newsdemo://…) but, on recent macOS, not a script in Terminal.
-- This tiny app receives the link and tells Terminal to run the matching script with bash.
-- Built and registered by presentation/run/install-runner.sh. __REPO__ is replaced with the repo path.

property repo : "__REPO__"

on run
	-- Started by double-click: nothing to do. Started by a newsdemo:// link: see open location.
end run

on open location theURL
	set scriptName to ""
	if theURL starts with "newsdemo://run-tests" then
		set scriptName to "1-run-tests.command"
	else if theURL starts with "newsdemo://break-it" then
		set scriptName to "2-break-it.command"
	else if theURL starts with "newsdemo://show-diff" then
		set scriptName to "3-show-diff.command"
	else if theURL starts with "newsdemo://back-to-main" then
		set scriptName to "4-back-to-main.command"
	end if
	if scriptName is "" then return
	set scriptPath to repo & "/presentation/run/" & scriptName
	do shell script "mkdir -p " & quoted form of (repo & "/artifacts") & " && echo \"$(date '+%H:%M:%S') " & scriptName & "\" >> " & quoted form of (repo & "/artifacts/runner.log")
	set theCommand to "bash " & quoted form of scriptPath
	tell application "Terminal"
		activate
		if (count of windows) is 0 then
			do script theCommand
		else
			do script theCommand in front window
		end if
	end tell
end open location
