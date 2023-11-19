#define MAX_HISTORY 16
#define INPUT_BUF 128


struct historyBufferArray{
    char bufferArr[MAX_HISTORY][INPUT_BUF];
    uint lengthArr[MAX_HISTORY];
    uint lastCommandIndex;
    int numOfCommandsInMem;
    char currentCommand[INPUT_BUF];
};

extern struct historyBufferArray historyBuffer;
