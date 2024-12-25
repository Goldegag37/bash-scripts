# bash-scripts
some bash scripts i made
## roku.sh
a script that can control a roku player via wifi.

you may need to enable contol via wifi at:

Home > Settings > System > Advanced System Settings > Control by moble apps > Network access

on first run it will ask you if you want to automaticaly find the IP of your roku or input the IP.     
there are more commands than displayed; read the code for roku_input to find them

## thirdtube-import.sh
a script to copy your youtube subscriptions to thirdtube.
how to use:
1. go to https://takeout.google.com/
2. click "Deselect all" and scroll down to "YouTube and YouTube Music"
3. click the checkbox next to "YouTube and YouTube Music" then "Next step"
4. choose the desired settings (this won't effect the process) then click "Create Export"
5. wait.
6. once you have the data, unzip the .zip or .tgz file
7. copy Takeout/Youtube and Youtube Music/subscriptions/subscriptions.csv to the same folder as the script
8. run the script
9. copy subscription.json to
# script might be broken, not sure.
