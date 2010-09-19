// TODO
integer REFEREE_CHANNEL = -152913;
string REMOVE_SHEEP_MESSAGE = "REMOVE SHEEP";

// TODO
integer TOTAL_SHEEP = 15;
integer IN_GAME_SHEEP = 3;

integer nextSheepID = 1;

integer score1 = 0;
integer score2 = 0;

createSheep() {
  llRezObject("$sheep", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, nextSheepID);
  nextSheepID++;
}

endGame() {
  llShout(REFEREE_CHANNEL, "REMOVE SHEEP");
  llShout(0, "Game Ended. Final Score:");
  llShout(0, "Team 1: " + (string)score1 + ", Team 2: " + (string)score2);
  state default;
}

default {
  touch_start(integer num) {
    // Initialize game variables
    nextSheepID = 1;
    score1 = 0;
    score2 = 0;

    integer i;
    for(i = 0; i < IN_GAME_SHEEP; i++)
      createSheep();

    llShout(0, "Game has started.");
    state play;
  }
}

state play {
  touch_start(integer num) {
    endGame();
  }
}

