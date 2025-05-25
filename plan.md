
1. wayland (done)
2. intial promt to exit- aka what is mean is lets say if in the 1st section or the initial promt of the code to make a new file on there adding a way / feature to /exit or /history so we can just exit if we started the aihelp by mistake and /history is for yk continuing a chat .(done)
3. markdown (done)
4. models adding like all (done)
5. models naming for json  (done)
6. OR works no /history errors (done)
7. OR models and Gemini cross uses /history (done)
8. copy func working again.. (done)
9. multi liner paste fixed also on a git commit branch (done)
10. gum rewrite to replace input taking using read (done)
11. gum rewrite to replace copy selection of code blocks to use gum choose not tipical bash read-input (done dev2)
12. initial start of the script when ran should be pretty with colorfull box inside which text saying aihelp . use ascii art like this 

  ,-.   ,-.  
 ( O ) (o.o)  
  `-’   |_)  oliveowl 
    “who?”

and then use colors on intial starting of the script use colors to make the command look coloufull .rn it uses gum but gum styl is quite slow so we not gona use that .so 1st make the whole project oliveowl as name and then use the ascii art with perple color . and remove the aihelp box of gum . make the initial text colored with echo and bold with echo and not gum . i mean color the commands use perple color as base for styling whole script . 
(done dev2)


13. make the initial welcome and instruction msg none perple to light blue . make the ascci art bold . (done dev2 )

14. in chat convo make You: and AI(): bold and use perple for ai bodel and blue for You: (done dev2)

15. add gum animation in the time of api loading to generate response  (done dev2)

16. in the initial welcome / starting the gum input to name the history file we can input /history or /config. i want you to add a way to input /config too on that starting point (done dev2)

17. as new gemini and open router models droping every day . hardcoding model name in the main script is a bad idea make a plan for this .
(done dev2) --fetching script and manual adding (done dev2 )

18. update the  read me by the recent update of code .  and add the vid https://youtu.be/mkkkX1Grqs8 . also explaning how to install for all unix like systems . add this ascii on repo start or something . in readme also adding that this project was inspired by warp ai terminal and gemini 2.5 was a huge help 

  ,-.   ,-.  
 ( O ) (o.o)  
  `-’   |_)  oliveowl 
    “who?”

(done dev2)
19. in the mid of chatting with the ai if we change the model via /config it tends to make a new chat by prompting me to name the file but its not extected tho. cause in mid chat it should just continue the chat .
(done dev2)

20. nvim / any terminal editor added /view to get a great view on the chat (done dev2)
21. ollama integration (done dev2)
23. if any errors happens during chat it should ask users to retry or leave via gum choose . so give like 2 option after error to error  add a way to retry the same user propmpt  prompt if Error: API call failed. infinty loop with for retry until cancel . using cancel the script should end aka exit  .(done dev2)
24. while looped copy feature so like after taking one copy it will prompt for more until cancel was chose . so in general after giving any code block it propmpt copy with gum and xlicp or the wayland one. but it only lasts for one code block i want you to make a way to let me copy until i choose cancel . so like lets say it gave 4 code block i will chose 1st one then with a loop u will exclude the one that i chose and give me another chnace to copy any of the rest of the blocks . if i copy all the blocks then loop will end and gum write with prompt should code back for next prompt (done dev2 )
25. add a way to check token speed via timer aka how much time it took for the response to arive then time/token . it should be counted on client side  and not using api or server side  . and token speed means token or word / time it take for the output to arive (done dev2 )
26. adding a way to check the history files in bat fzf view aka the jsons when /history was tiped .  like this is an exmple code that i use on getting files as bat view and search fast with fzf . something similar to this but only for the history jsons . 

    set file (find $HOME -type f -print0 | fzf --read0 --preview 'bat --style=numbers --color=always {}' --preview-window=right:60%:wrap --bind ctrl-/:toggle-preview)