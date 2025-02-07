USING Siemens.Simatic.S71500.MotionControl.Native;

NAMESPACE My.Tiax.MotionControl

    TYPE
        ExecState : USINT
            (Idle := usint#0, Init := usint#1, Power := usint#2
            , Home := usint#3, Gearing := usint#4, Positioning := usint#5, GearOut := USINT#6
            , Error := usint#13) := Idle;
    END_TYPE

    FUNCTION_BLOCK  SampleAxisFB
        VAR_INPUT
            axisPos     : DB_ANY;
            axisSync    : DB_ANY;

            execute     : BOOL;
            requiredPos : LREAL;
        END_VAR

        VAR
            execState   : ExecState;
            prevExecute : BOOL;

            powerPos, powerSync : Mc_Power;
            homePos, homeSync   : Mc_Home;
            moveAbs             : MC_MoveAbsolute;
            gearInPos           : MC_GearInPos;
            gearOutPos          : MC_GearOut;
        END_VAR

        IF execute <> prevExecute  THEN
            prevExecute := execute;
            IF prevExecute  THEN
                execState := ExecState#Init;
            END_IF;
        END_IF;

        CASE execState OF
            ExecState#Init:
                // verify passed DBs
                IF AsPositioningAxisRef(axisPos) <> null AND AsSynchronousAxisRef(axisSync) <> null  THEN
                    execState := ExecState#Power;
                ELSE
                    execState := ExecState#Error;
                END_IF;

            ExecState#Power:
                // power on the positioning and synchronous axis
                powerPos(Axis := AsAxisRef(axisPos)^, enable := TRUE);
                IF powerPos.Error = TRUE  THEN
                    execState := ExecState#Error;
                END_IF;
                powerSync(Axis := AsAxisRef(axisSync)^, enable := TRUE);
                IF powerSync.Error = TRUE  THEN
                    execState := ExecState#Error;
                END_IF;

                IF powerSync.Status = TRUE AND powerPos.Status = TRUE  THEN
                    homePos(Axis := AsAxisRef(axisPos)^, execute := FALSE);
                    homeSync(Axis := AsAxisRef(axisSync)^, execute := FALSE);
                    execState := ExecState#Home;
                END_IF;

            ExecState#Home:
                // home positioning and synchronous axis
                homePos(Axis := AsAxisRef(axisPos)^, execute := TRUE, mode := 0, Position := LREAL#0.0);
                IF (homePos.Error = TRUE) THEN
                    execState := ExecState#Error;
                END_IF;
                homeSync(Axis := AsAxisRef(axisSync)^, execute := TRUE, mode := 0, Position := LREAL#0.0);
                IF (homeSync.Error = TRUE) THEN
                    execState := ExecState#Error;
                END_IF;

                IF homeSync.Done = TRUE AND homePos.Done = TRUE  THEN
                    gearInPos(Master := AsAxisRef(axisPos)^
                        , Slave := AsSynchronousAxisRef(axisSync)^
                        , execute := FALSE);
                    execState := ExecState#Gearing;
                END_IF;

            ExecState#Gearing:
                // connect synchronous axis (Slave) to positioning axis (Master)
                gearInPos(Master := AsAxisRef(axisPos)^, Slave := AsSynchronousAxisRef(axisSync)^,
                    Execute            := TRUE,
                    RatioNumerator     := DINT#2,
                    RatioDenominator   := DINT#1,
                    MasterSyncPosition := LREAL#0.0,
                    SlaveSyncPosition  := LREAL#0.0,
                    SyncProfileReference := DINT#3, // ab pos 0 nachlaufend aufsynchronisieren
                    MasterStartDistance := requiredPos/LREAL#2.0
                );

                IF gearInPos.Busy = TRUE  THEN
                    moveAbs(Axis := AsPositioningAxisRef(axisPos)^, Execute := FALSE);
                    execState := ExecState#Positioning;
                END_IF;

            ExecState#Positioning:
                // positioning the leading axis
                moveAbs(Axis := AsPositioningAxisRef(axisPos)^
                    , Execute := TRUE
                    , Position := requiredPos
                    , Velocity := LREAL#50.0
                    , Direction := 3
                );

                IF moveAbs.Error = TRUE  THEN
                    execState := ExecState#Error;
                ELSIF (moveAbs.Done = TRUE) then
                    execState := ExecState#GearOut;
                    gearOutPos(execute := FALSE, Slave := AsSynchronousAxisRef(axisSync)^);

                END_IF;

            ExecState#GearOut:
                gearOutPos(execute := TRUE, Slave := AsSynchronousAxisRef(axisSync)^, SlavePosition := requiredPos * 2.0, SyncProfileReference := 0);

                IF gearOutPos.Error = TRUE  THEN
                    execState := ExecState#Error;
                ELSIF (gearOutPos.Done = TRUE) then
                    execState := ExecState#Idle;
                END_IF;

            ExecState#Error:
                ;
            ELSE // idle
                ;
        END_CASE;

    END_FUNCTION_BLOCK

END_NAMESPACE