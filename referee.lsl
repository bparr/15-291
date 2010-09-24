// Channel to use to communicate with sheep
integer REFEREE_CHANNEL = -152913;

// The total number of sheep for the game
integer TOTAL_SHEEP = 15;

// The maximum number of sheep in play
integer IN_GAME_SHEEP = 3;

// The game time limit so games don't go on forever
float TIME_LIMIT = 600.0; // 10 minutes

// Value for scoring a touchdown
integer TOUCHDOWN_VALUE = 5;

// Value for scoring a field goal
integer FIELD_GOAL_VALUE = 2;

// The next sheep ID to use
integer nextSheepID = 1;

// The number of sheep that have been scored
integer scoredSheep = 0;

// The current score
integer score1 = 0;
integer score2 = 0;

// Create a sheep located at pos
createSheep(vector pos) {
  llRezObject("$sheep", pos, ZERO_VECTOR, ZERO_ROTATION, nextSheepID++);
}

printScore() {
  llShout(0, "Red Team: " + (string)score1 + "\t\tGreen Team: " + (string)score2);
}

// End the game, removing all sheep from the field
endGame() {
  llShout(REFEREE_CHANNEL, "end");
  llShout(0, "Game Ended. Final Score:");
  printScore();
  state default;
}

// Game is not being played
default {
  // Allow avatars to touch the referee to begin a game
  touch_start(integer num) {
    // Initialize game variables
    nextSheepID = 1;
    scoredSheep = 0;
    score1 = 0;
    score2 = 0;

    integer i;
    vector pos = llGetPos();
    for(i = 0; i < IN_GAME_SHEEP; i++)
      createSheep(pos);

    llShout(0, "Game started.");
    state play;
  }
}

// Game is being played
state play {
  state_entry () {
    llListen(REFEREE_CHANNEL, "", NULL_KEY, "");
    llSetTimerEvent(TIME_LIMIT);
  }

  // Allow avatars to touch the referee to end a game early
  touch_start(integer num) {
    endGame();
  }

  // Enforce game time limit
  timer() {
    llSetTimerEvent(0);
    llShout(0, "Time is up");
    endGame();
  }

  // Listen for messages from scored sheep
  listen(integer channel, string name, key id, string message) {
    list parsedMessage = llParseString2List(message, [","], []);
    if(llGetListLength(parsedMessage) != 2)
      return;

    // Parse the first part of the message that tells what type of score it was
    integer score = 0;
    string firstPart = llList2String(parsedMessage, 0);
    if(firstPart == "touchdown")
      score = TOUCHDOWN_VALUE;
    else if(firstPart == "field goal")
      score = FIELD_GOAL_VALUE;
    else
      return;

    // Parse the second part of the message that tells which team scored
    string secondPart = llList2String(parsedMessage, 1);
    if(secondPart == "1")
      score1 += score;
    else if(secondPart == "2")
      score2 += score;
    else
      return;

    // TODO create sheep inside holding area
    // TODO update scoreboard?

    // Notify everyone of the score
    if(secondPart == "1")
      llShout(0, "Red Team scored a " + firstPart);
    else
      llShout(0, "Green Team scored a " + firstPart);

    // Check to see if the game ended by all sheep being scored
    scoredSheep++;
    if(scoredSheep == TOTAL_SHEEP) {
      llShout(0, "All sheep have been scored");
      endGame();
    }

    printScore();

    // Create a new sheep if there are still more
    if(nextSheepID <= TOTAL_SHEEP)
      createSheep(llGetPos());
  }
}

