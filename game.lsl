// TODO

integer listenHandle;

default {
  touch_start(integer num) {
    llSay(0, "Game has started.");
    string name = llGetInventoryName(INVENTORY_OBJECT, 0);
    llSay(0, name);
//    state play;
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
