// The id of the sheep, initialized when the sheep is created
integer SHEEP_ID = -1;

// Center of the field
float CENTER_X = 128.0;
float CENTER_Y = 128.0;

// Dimensions of the field
float LENGTH = 100.0;
float WIDTH = 50.0;

// The z position of the sheep
float SHEEP_Z = 25.44;

// Length of the center zone
float CENTER_ZONE_LENGTH = 20.0;

// Length of the field goal zone
float FIELD_GOAL_ZONE_LENGTH = 25.0;

// Lenght of the touchdown goal zone
float TOUCHDOWN_ZONE_LENGTH = 1.0;

// Probability of moving toward center zone when roaming outside the zone
float CENTER_PROBABILITY = .75;

// Number of seconds in between checking for dogs and direction changes
// when in the roaming state
float ROAMING_INTERVAL = 0.5;

// The sheep's range of sight (for sensing a dog)
float SIGHT_RANGE = 10.0;

// The distance the sheep runs when it detects a dog while roaming
float SPRINT_DISTANCE = 20.0;

// Number of seconds sheeps rests after sprinting away from a dog
float REST_TIME = 12.0;

// The channel to use to communicate with the referee
integer REFEREE_CHANNEL = -152913;

// The name of the referee
string REFEREE_NAME = "Referee";

// Second Life limits the distance llSetPos can move an object,
// so it may need to be called multiple times to acually set the position
llActuallySetPos(vector pos) {
  while(llVecDist(llGetPos(), pos) > 0.01)
    llSetPos(pos);
}

// Set the sheep's game position using X and Y offsets, accounting for
// ricochets off of walls
llMoveByOffset(float offsetX, float offsetY) {
  vector pos = llGetPos();
  float x = pos.x + offsetX;
  float y = pos.y + offsetY;

  // Calculate the X and Y distance outside of the boundaries
  float outOfBoundsX = llFabs(x - CENTER_X) - LENGTH / 2;
  float outOfBoundsY = llFabs(y - CENTER_Y) - WIDTH / 2;

  // Account for ricochet if the given offset will push the sheep out of bounds
  if(outOfBoundsX > 0.0) {
    if(x > CENTER_X)
      x -= 2 * outOfBoundsX;
    else
      x += 2 * outOfBoundsX;

    offsetX = x - pos.x;
  }

  if(outOfBoundsY > 0.0) {
    if(y > CENTER_Y)
      y -= 2 * outOfBoundsY;
    else
      y += 2 * outOfBoundsY;

    offsetY = y - pos.y;
  }

  llSetRot(llEuler2Rot(<0.0, 0.0, llAtan2(offsetY, offsetX) + PI_BY_TWO>));
  llActuallySetPos(<x, y, SHEEP_Z>);
}

// Given two arbitrary offsets, sprint SPRINT_DISTANCE
sprint(float offsetX, float offsetY) {
  vector offset = <offsetX, offsetY, 0.0>;

  if(offset != ZERO_VECTOR) {
    // Sprint in given direction
    offset = SPRINT_DISTANCE * llVecNorm(offset);
    llMoveByOffset(offset.x, offset.y);
  }
  else {
    // Sprint in random direction
    float r = llFrand(TWO_PI);
    llMoveByOffset(SPRINT_DISTANCE * llCos(r), SPRINT_DISTANCE * llSin(r));
  }
}

// Handle a message from the referee
handleRefereeChat(string message) {
  if(message == "end")
    llDie();
}

// Initialize sheep
default {
  on_rez(integer id) {
    if(id == 0)
      return;

    SHEEP_ID = id;
    llSetObjectName(llGetObjectName() + (string)SHEEP_ID);

    // Move sheep to starting position
    float posY = CENTER_Y;

    // Special case for initial game position
    if(SHEEP_ID == 1)
      posY += WIDTH / 4.0;
    else if (SHEEP_ID == 2)
      posY -= WIDTH / 4.0;

    llActuallySetPos(<CENTER_X, posY, SHEEP_Z>);

    state roaming;
  }
}

// Roaming state where sheep stays near the center, and checks for dogs
state roaming {
  state_entry() {
    if(llGetAttached())
      state captured;

    llListen(REFEREE_CHANNEL, REFEREE_NAME, NULL_KEY, "");
    llSensorRepeat("", "", AGENT, SIGHT_RANGE, PI, ROAMING_INTERVAL);
  }


  // Sheep senses a dog, so sprint away
  sensor(integer num) {
    // TODO ensure actually sensed a dog, instead of a master
    llSensorRemove();

    vector pos = llGetPos();
    vector offset = ZERO_VECTOR;

    // Calculate direction to sprint based on locations of detected dogs
    integer i;
    for(i = 0; i < num; i++)
      offset += (pos - llDetectedPos(i));

    sprint(offset.x, offset.y);
    state rest;
  }

  // No dog was sensed, so roam a distance of 1 meter
  no_sensor() {
    vector pos = llGetPos();

    float r = llFrand(TWO_PI);
    float offsetX = llCos(r);
    float offsetY = llSin(r);

    // Whether the current X offset will move the sheep towards the center
    // Calculated by checking if the offsets have the same signs
    integer towardsCenterX = (offsetX * (CENTER_X - pos.x) > 0.0);

    // Weight movement toward the center line if outside the center zone
    if(llFabs(pos.x - CENTER_X) > CENTER_ZONE_LENGTH / 2) {
      integer moveToCenterLine = (llFrand(1.) < CENTER_PROBABILITY);

      // Fix inconsistency with the wanted result and the current offset
      if(towardsCenterX != moveToCenterLine)
        offsetX *= -1;
    }

    llMoveByOffset(offsetX, offsetY);
  }

  // Detect whether the sheep is captured
  attach(key id) {
    if(id != NULL_KEY) {
      llSensorRemove();
      state captured;
    }
  }

  // Listen for messages from the referee
  listen(integer channel, string name, key id, string message) {
    handleRefereeChat(message);
  }
}

// Resting state after sheep ran away from a dog
state rest {
  state_entry() {
    if(llGetAttached())
      state captured;

    llListen(REFEREE_CHANNEL, REFEREE_NAME, NULL_KEY, "");
    llSetTimerEvent(REST_TIME);
  }

  // Sheep is done resting. Re-enter roaming state
  timer() {
    llSetTimerEvent(0);
    state roaming;
  }

  // Detect whether the sheep is captured
  attach(key id) {
    if(id != NULL_KEY) {
      llSetTimerEvent(0);
      state captured;
    }
  }

  // Listen for messages from the referee
  listen(integer channel, string name, key id, string message) {
    handleRefereeChat(message);
  }
}

// Sheep is attached to an avatar (i.e. captured)
state captured {
  state_entry() {
    // Ensure the sheep is attached
    if(!llGetAttached())
      state roaming;

    llListen(REFEREE_CHANNEL, REFEREE_NAME, NULL_KEY, "");
  }

  // Detect when the sheep is dropped
  attach(key id) {
    if(id == NULL_KEY) {
      vector pos = llGetPos();

      // TODO ensure the team of the dog and the closest goal are the same
      // (i.e. don't allow scoring for the other team)
      float endDistance = (LENGTH / 2) - llFabs(pos.x - CENTER_X);

      // Sheep was scored, so show message and reset sheep
      if(endDistance < FIELD_GOAL_ZONE_LENGTH) {
        // Determine which team scored
        integer team = 1;
        if (pos.x > CENTER_X)
          team = 2;

        // Tell the referee that the sheep was scored
        if(endDistance < TOUCHDOWN_ZONE_LENGTH)
          llShout(REFEREE_CHANNEL, "touchdown," + (string)team);
        else
          llShout(REFEREE_CHANNEL, "field goal," + (string)team);

        llDie();
      }
      else {
        // Sheep dropped without scoring, so sprint toward center point.
        sprint(CENTER_X - pos.x, CENTER_Y - pos.y);
        state roaming;
      }
    }
  }

  // Listen for messages from the referee
  listen(integer channel, string name, key id, string message) {
    handleRefereeChat(message);
  }
}

