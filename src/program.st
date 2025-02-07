USING My.Tiax.MotionControl;

PROGRAM MyProgram
    VAR_EXTERNAL
        RequiredPos : LREAL;
        Execute     : BOOL;
        MotionFB    : SampleAxisFB;
    END_VAR

    VAR
    END_VAR

    VAR CONSTANT
        posAxisDB   : UINT := UINT#2;
        syncAxisDB  : UINT := UINT#3;
    END_VAR

    MotionFB(posAxisDB, syncAxisDB, Execute, RequiredPos);
    
END_PROGRAM