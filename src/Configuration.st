USING My.Tiax.MotionControl;

CONFIGURATION MyConfiguration
    TASK Main(Interval := T#10ms, Priority := 1);
    PROGRAM P1 WITH Main: MyProgram;

    VAR_GLOBAL
        RequiredPos : LREAL := 1000.0;
        Execute     : BOOL;
        MotionFB    : SampleAxisFB;
    END_VAR
END_CONFIGURATION
