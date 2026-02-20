# TODO

## Cleanup

- Hide frame by default
- Add commands "s", "o", and "open", "h", and "hide" to toggle the frame 
- The gold slider container should parent to the module button, so we don't need to offset from the top of the frame. So if we want to add a button above the module button everything will move down correctly. 

## Smaller Features
- Make a high pays low module so we can test two modules
- Update the module button to open a dropdown where we can select from available modules (games)

## Major Features
### Store winnings and losses
We should store winnings and losses in a database so we can see people's lifetime amounts of gold won or lost. 

Ideally we'd be able to store the amounts linked to the battle.net account so them changing characters doens't count seperately.

if not possible we should update the whole app to use use name-server so we don't combine two people with the same on diff servers. 

We should also store the guild the character is in so we can have info only for the members of my guild.
