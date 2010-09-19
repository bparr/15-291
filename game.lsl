// TODO
integer TOTAL_SHEEP = 15;
integer IN_GAME_SHEEP = 3;

integer nextSheepID = 1;

integer listenHandle; // TODO remove?

createSheep() {
  llRezObject("$sheep", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, nextSheepID);
  nextSheepID++;
}

default {
  touch_start(integer num) {
    integer i;
    for(i = 0; i < IN_GAME_SHEEP; i++)
      createSheep();

    llSay(0, "Game has started.");
    state play;
  }
}

state play {
  state_entry() {
    //listenHandle  = llListen(0, "", NULL_KEY, "");
    llSay(0, "asdf");
  }
  listen(integer channel, string name, key id, string message) {
    llSay(0, "FOO: " + (string)channel + ", " + name + ", " + (string)id + ", " + message);
    llListenRemove(listenHandle);
  }
}
