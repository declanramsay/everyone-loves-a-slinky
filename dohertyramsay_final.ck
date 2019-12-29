//UGens
SndBuf back => BPF notch => PitShift swing => JCRev hands => dac;
SndBuf countries => hands;

// Global + Setup Variables

0 => int i;
0 => float pitching;
0 => float mydelay;
1 => notch.Q;
0.5 => swing.mix;
1 => back.loop; 

// Samples and Directories
me.dir() => string path;
"/audio/smokestretched.wav" => string myback;
"/audio/vs-countries.aif" => string mycountries;

// changes the filenames to full pathnames
path + myback => myback;
path + mycountries => mycountries;


//read those files
myback => back.read;
mycountries => countries.read;


// Starting Mute
0 => back.gain;
0.1 => countries.gain;


// Serial Stuff
SerialIO serial;
string line;
string stringInts[3];
int data[3];
SerialIO.list() @=> string list[];
// prints out the available serial devices
// uses "C-Style" printing instead of <<< >>>
for(int i; i<list.cap(); i++){
    chout <= i <= ": " <= list[i] <= IO.newline();
}
// open serial port 2 at 9600 baud, set to output ACSII (not binary)
serial.open(2, SerialIO.B9600, SerialIO.ASCII);

// Functions

fun void serialPoller() {
    while(true){
        serial.onLine() => now; //wait for arrival or serial….
        serial.getLine() => line; // store serial data in string 'line'
        // if it is null, break out and go back to waiting for serial
        if(line$Object == null) continue;
        0 => stringInts.size;
        //if messages are threee comma-separated numbers w/ sq. breackets at end,
        //then store the three strings in the stringInts array.
        if (RegEx.match("\\[([0-9]+),([0-9]+)\\]", line, stringInts)){
            
            //now loop through and convert from ascii to int…
            //store these new ints into the "data" array
            for(1 => int i; i < stringInts.cap(); i++){
                Std.atoi(stringInts[i]) => data[i-1];
            }
        }
    }
}
 // Mapping function
fun float map(float x, float in_min, float in_max, float out_min, float out_max) {
    return (x-in_min)*(out_max-out_min)/(in_max-in_min)+out_min;
}

// Making math!
fun void mathIsHard() {
    map(data[0], 0, 1023, 0, 1000) => float newFloatValue;
    
    Math.pow(newFloatValue, 10) => float newFloatValue2;
    0.0000000000000000000000001 *=> newFloatValue2;
    200 +=> newFloatValue2;
    
    
    // Creates hard top limits to not blow speakers
    if(newFloatValue2 > 19000) {
        19000 => newFloatValue2;
    }
    
    if(mydelay > .95) {
        .95 => mydelay;
    }
    
    newFloatValue2 => notch.freq;
}


spork ~ serialPoller();
spork ~ mathIsHard();

while(true) {
    0.8 => back.gain;
    
    // data[0]
    data[0] => pitching;
    200 /=> pitching;
    pitching => swing.shift;
    
    // data[1]
    data[1] => float mydelay;
    data[1] => float playpos;
    
    // Delay
    1000 /=> mydelay;
    mydelay => hands.mix;
    
    // Play Position
    
    1000 /=> playpos; //from 0 to 1
    2 *=> playpos; // 0 to 2
    1 -=> playpos; // -1 to +1
    playpos => countries.rate;
    
    
    
   // This next section makes sure the countries sample loops backwards and forwards
    if (countries.pos() == countries.samples() ) {
        1 => countries.pos;
    }
    
    else if (countries.pos() == 0) {
        countries.samples() - 1 => countries.pos;
    }

    <<<data[0], data[1]>>>;
    1::ms => now;
}